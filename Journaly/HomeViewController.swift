//
//  HomeViewController.swift
//  Journaly
//
//  Created by Yuying Fan on 12/17/21.
//

import UIKit
import JTAppleCalendar
import FirebaseDatabase

class HomeViewController: UIViewController, AddJournalDelegate {
    
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var streakLabel: UILabel!
    @IBOutlet weak var monthYearLabel: UILabel!
    @IBOutlet weak var calendarView: JTACMonthView!
    
    let formatter = DateFormatter()
    
    let monthColor = UIColor.white
    let outMonthColor = UIColor(red: 230, green: 210, blue: 210)
    let hasJournalCellTextColor = UIColor(red: 202, green: 165, blue: 158)
    
    var streakDays = 0
    
    private let database = Database.database().reference()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.addButton.isEnabled = false
        
        // Update and store the streak days
        formatter.dateFormat = "yyyy-MM-dd"
        self.database.child("journals").child(formatter.string(from: Date())).observeSingleEvent(of: .value, with: { snapshot in
            if (snapshot.exists()) {
                self.database.child("streak").observeSingleEvent(of: .value, with: { snapshot in
                    guard let streakDaysData = snapshot.value as? Int else {
                        self.streakLabel.text = "Failed to retrieve streak info. What is wrong?"
                        return
                    }
                    if (streakDaysData == 0) {
                        self.streakLabel.text = "Glad to See You.\nJot Something Down!"
                    } else {
                        self.streakLabel.text = "You have a \(streakDaysData) day streak.\nKeep it up!"
                    }
                    self.streakDays = streakDaysData
                })
            } else {
                self.formatter.dateFormat = "yyyy-MM-dd"
                let dateStr = self.formatter.string(from: Date.yesterday)
                print(dateStr)
                self.database.child("journals").child(dateStr).observeSingleEvent(of: .value, with: { snapshot in
                    if (!snapshot.exists()) {
                        self.streakLabel.text = "Glad to See You.\nJot Something Down!"
                        self.streakDays = 0
                        self.database.child("streak").setValue(0)
                    } else {
                        self.database.child("streak").observeSingleEvent(of: .value, with: { snapshot in
                            guard let streakDaysData = snapshot.value as? Int else {
                                self.streakLabel.text = "Failed to retrieve streak info. What is wrong?"
                                return
                            }
                            if (streakDaysData == 0) {
                                self.streakLabel.text = "Glad to See You.\nJot Something Down!"
                            } else {
                                self.streakLabel.text = "You have a \(streakDaysData) day streak.\nKeep it up!"
                            }
                            self.streakDays = streakDaysData
                        })
                    }
                })
            }
        })
        
        calendarView.scrollToDate(Date())
        calendarView.visibleDates { visibleDates in
            self.setMonthYearLabelText(from: visibleDates)
        }
    }
    
    func setMonthYearLabelText(from visibleDates: DateSegmentInfo) {
        let date = visibleDates.monthDates.first!.date
        formatter.dateFormat = "yyyy MMMM"
        monthYearLabel.text = formatter.string(from: date)
    }
    
    func setCellTextColor(cell: JTACDayCell?, cellState: CellState) {
        guard let validCell = cell as? CustomCell else { return }
        if cellState.dateBelongsTo == .thisMonth {
            validCell.dateLabel.textColor = monthColor
        } else {
            validCell.dateLabel.textColor = outMonthColor
        }
    }
    
    // Highlights today's date
    func setCellSelectedView(cell: JTACDayCell?, cellState: CellState) {
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: cellState.date)
        guard let validCell = cell as? CustomCell else { return }
        self.database.child("journals").child(dateStr).observeSingleEvent(of: .value, with: { snapshot in
            // Highlight the cell if it has a journal
            if (snapshot.exists()) {
                validCell.dateLabel.textColor = self.hasJournalCellTextColor
                validCell.selectedView.backgroundColor = UIColor.white
                validCell.selectedView.isHidden = false
                validCell.showDetailsButton.isEnabled = true
                self.formatter.dateFormat = "yyyyMMdd"
                validCell.showDetailsButton.tag = (self.formatter.string(from: cellState.date) as NSString).integerValue
            } else {
                // Highlight the cell if it's today
                let today = Date()
                self.formatter.dateFormat = "yyyy-MM-dd"
                let todayStr = self.formatter.string(from: today)
                let cellStr = self.formatter.string(from: cellState.date)
                if todayStr == cellStr {
                    self.addButton.isEnabled = true
                    validCell.dateLabel.textColor = UIColor.white
                    validCell.selectedView.isHidden = false
                } else {
                    validCell.dateLabel.textColor = UIColor.white
                    validCell.selectedView.isHidden = true
                }
                validCell.showDetailsButton.isEnabled = false
            }
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         if (segue.identifier == "detailSegue") {
             let dateStr = ((sender as! UIButton).tag as NSNumber).stringValue
             formatter.dateFormat = "yyyyMMdd"
             let date = formatter.date(from: dateStr)!
             let detailController = (segue.destination as! UINavigationController).topViewController as! JournalDetailViewController
             detailController.date = date
             formatter.dateFormat = "yyyy-MM-dd"
             self.database.child("journals").child(formatter.string(from: date)).observeSingleEvent(of: .value, with: { snapshot in
                 // Highlight the cell if it has a journal
                 guard let journalStr = snapshot.value as? String else {
                     print("Failed to lookup journal in database with date \(dateStr)")
                     return
                 }
                 let entries = journalStr.components(separatedBy: "@#@#@#")
                 detailController.thankLabel.text = entries[0]
                 detailController.thoughtLabel.text = entries[1]
                 detailController.wishLabel.text = entries[2]
             })
        }
        if (segue.identifier == "addSegue") {
            ((segue.destination as! UINavigationController).topViewController as! AddJournalViewController).delegate = self
        }
    }
    
    func didCreate(_ journal: Journal) {
        // Dismiss the child views (add journal view)
        dismiss(animated: true, completion: nil)
        // Reload the calendar view
        self.calendarView.reloadDates([Date()])
        // Add the new journal entry to database
        formatter.dateFormat = "yyyy-MM-dd"
        self.database.child("journals").child(formatter.string(from: journal.date)).setValue(journal.thank + "@#@#@#" + journal.thought + "@#@#@#" + journal.wish)
        streakDays += 1
        self.streakLabel.text = "You have a \(streakDays) day streak.\nKeep it up!"
        self.database.child("streak").setValue(streakDays)
        self.addButton.isEnabled = false
    }

}

extension HomeViewController: JTACMonthViewDataSource {
    func configureCalendar(_ calendar: JTACMonthView) -> ConfigurationParameters {
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = Calendar.current.timeZone
        formatter.locale = Calendar.current.locale
        
        let startDate = formatter.date(from: "2021-11-01")!
        let endDate = Date()
        
        let parameters = ConfigurationParameters(startDate: startDate, endDate: endDate)
        return parameters
    }
    
}

extension HomeViewController: JTACMonthViewDelegate {
    
    func calendar(_ calendar: JTACMonthView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTACDayCell {
        let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "CustomCell", for: indexPath) as! CustomCell
        cell.dateLabel.text = cellState.text
        setCellTextColor(cell: cell, cellState: cellState)
        setCellSelectedView(cell: cell, cellState: cellState)
        return cell
    }
    
    func calendar(_ calendar: JTACMonthView, willDisplay cell: JTACDayCell, forItemAt date: Date, cellState: CellState, indexPath: IndexPath) {
        let cell = cell as! CustomCell
        cell.dateLabel.text = cellState.text
        setCellTextColor(cell: cell, cellState: cellState)
        setCellSelectedView(cell: cell, cellState: cellState)
        cell.showDetailsButton.isEnabled = true
    }
    
    func calendar(_ calendar: JTACMonthView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
        setMonthYearLabelText(from: visibleDates)
    }
    
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        let newRed = CGFloat(red)/255
        let newGreen = CGFloat(green)/255
        let newBlue = CGFloat(blue)/255
        
        self.init(red: newRed, green: newGreen, blue: newBlue, alpha: 1.0)
    }
}

extension Date {
    static var yesterday: Date { return Date().dayBefore }
    static var tomorrow:  Date { return Date().dayAfter }
    var dayBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: noon)!
    }
    var dayAfter: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: noon)!
    }
    var noon: Date {
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }
    var month: Int {
        return Calendar.current.component(.month,  from: self)
    }
    var isLastDayOfMonth: Bool {
        return dayAfter.month != month
    }
}

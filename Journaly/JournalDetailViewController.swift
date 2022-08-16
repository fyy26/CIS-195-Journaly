//
//  JournalDetailViewController.swift
//  Journaly
//
//  Created by Yuying Fan on 12/17/21.
//

import Foundation
import UIKit

class JournalDetailViewController: UIViewController {
    
    var date = Date()
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var thankLabel: UILabel!
    @IBOutlet weak var thoughtLabel: UILabel!
    @IBOutlet weak var wishLabel: UILabel!
    
    let formatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        formatter.dateFormat = "MM/dd/yyyy"
        dateLabel.text = formatter.string(from: date)
    }
    
    @IBAction func back(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

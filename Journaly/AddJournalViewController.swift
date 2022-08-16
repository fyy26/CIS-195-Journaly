//
//  AddJournalViewController.swift
//  Journaly
//
//  Created by Yuying Fan on 12/17/21.
//

import UIKit

protocol AddJournalDelegate: AnyObject {
    func didCreate(_ journal: Journal)
}

class AddJournalViewController: UIViewController, UITextViewDelegate {
    
    weak var delegate: AddJournalDelegate?
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var thankTextView: UITextView!
    @IBOutlet weak var thoughtTextView: UITextView!
    @IBOutlet weak var wishTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        thankTextView.delegate = self
        thoughtTextView.delegate = self
        wishTextView.delegate = self
        
        saveButton.isEnabled = false
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    // Validate all text field inputs are non empty
    func inputsNonEmpty() -> Bool {
        return !((thankTextView.text ?? "").isEmpty ||
                 (thoughtTextView.text ?? "").isEmpty ||
                 (wishTextView.text ?? "").isEmpty)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if inputsNonEmpty(){
            saveButton.isEnabled = true
        } else {
            saveButton.isEnabled = false
        }
    }
    
    @IBAction func save(_ sender: Any) {
        let journal = Journal(date: Date(), thank: thankTextView.text, thought: thoughtTextView.text, wish: wishTextView.text)
        self.delegate?.didCreate(journal)
    }
    
}

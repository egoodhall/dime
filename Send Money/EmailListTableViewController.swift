//
//  EmailListTableViewController.swift
//  Send Money
//
//  Created by Eric Marshall on 8/2/15.
//  Copyright (c) 2015 Eric Marshall. All rights reserved.
//

import UIKit
import RealmSwift

class EmailListTableViewController: UITableViewController {
    
    @IBAction func addRecipient(sender: UIBarButtonItem) {
        presentRecipientGetEmailController(nil);
    }

    let realm = try! Realm()
    var settings: Settings!
    var defaultTabFrame: CGRect!
    var selectedRows: [Int] = []
    var recipList: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Recipients"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(EmailListTableViewController.addRecipient(_:)))

        settings = realm.objects(Settings)[0] as Settings
        
        refreshData()
    }
    
    func refreshData() {
        recipList = []
        for recip in settings.emailList {
            recipList.append(recip.string)
        }

        recipList.sortInPlace {
            return $0.lowercaseString < $1.lowercaseString
        }
        for row in 0 ..< tableView.numberOfRowsInSection(0) {
            tableView.deselectRowAtIndexPath(NSIndexPath(forRow: row, inSection: 0), animated: true)
        }
    }

    
    //-------------------------------
    // MARK: - Table view data source
    //-------------------------------

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath) as UITableViewCell!
        
        cell.textLabel?.text = recipList[indexPath.row]

        return cell
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.recipList.count
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            for recipNum in 0 ..< settings.emailList.count {
                if settings.emailList[recipNum].string == recipList[indexPath.row] {
                    try! realm.write {
                        self.settings.emailList.removeAtIndex(recipNum)
                    }
                    break
                }
            }
            refreshData()
        }  
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performEditingAtIndexPath(indexPath)
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
       
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Delete") { (Action) in
            self.removeStringAtIndexPath(indexPath)
        }
        
        let editAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Edit") { (Action) in
            self.performEditingAtIndexPath(indexPath)
        }
        
        editAction.backgroundColor = .blueTintColor()
        
        return [deleteAction, editAction]
    }

    func performEditingAtIndexPath(indexPath: NSIndexPath) {
        print(self.recipList)
        let alert = UIAlertController(title: "Recipient", message: nil, preferredStyle: .Alert)

        alert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
            textField.keyboardType = .EmailAddress
            textField.placeholder = "Email"
            textField.text = self.recipList[indexPath.row]
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel){
            (Action) in
            self.tableView.setEditing(false, animated: true)
            self.refreshData()
        })

        alert.addAction(UIAlertAction(title: "Save", style: .Default) { Action in
            self.removeStringAtIndexPath(indexPath)

            var textFields = alert.textFields as [UITextField]!
            self.insertString(textFields[0].text!)

            self.tableView.setEditing(false, animated: true)
        })

        self.presentViewController(alert, animated: true, completion: nil)
    }

    func removeStringAtIndexPath(indexPath: NSIndexPath){
        try! self.realm.write {
            self.settings.emailList.removeAtIndex(indexPath.row)
        }
        self.recipList.removeAtIndex(indexPath.row)
        self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        self.refreshData()
    }

    //---------------------------------------
    // MARK: - Handling Addition of addresses
    //---------------------------------------

    func insertString(string: String){
        if let _ = string.rangeOfString("[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}", options: .RegularExpressionSearch)  {
            let emailString = EmailString(string: string)
            let ind = self.recipList.insertionIndexOf(string, isOrderedBefore: {return $0 < $1})
            try! self.realm.write {
                self.settings.emailList.insert(emailString, atIndex: ind)
            }
            self.recipList.insert(string, atIndex: ind)
            self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: ind, inSection: 0)], withRowAnimation: .Fade)
            self.refreshData()
        } else {
            presentRecipientGetEmailFailedController(string)
        }
    }

    func presentRecipientGetEmailFailedController(string: String) {
        let alert = UIAlertController(title: "Recipient", message: "'\(string)'\nIs not a valid email address.", preferredStyle: .Alert)

        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))

        alert.addAction(UIAlertAction(title: "Try Again", style: .Default) { Action in
            self.presentRecipientGetEmailController(string)
            })

        self.presentViewController(alert, animated: true, completion: nil)
    }

    func presentRecipientGetEmailController(string: String?) {
        let alert = UIAlertController(title: "Recipient", message: nil, preferredStyle: .Alert)

        alert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
            textField.keyboardType = UIKeyboardType.EmailAddress
            textField.placeholder = "Email"
            if string != nil {
                textField.text = string
            }
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))

        alert.addAction(UIAlertAction(title: "Save", style: .Default) { Action in
            var textFields = alert.textFields as [UITextField]!
            self.insertString(textFields[0].text!)
            })

        self.presentViewController(alert, animated: true, completion: nil)
    }
}

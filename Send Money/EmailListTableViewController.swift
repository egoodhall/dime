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
    
    @IBAction func addRecipient(_ sender: UIBarButtonItem) {
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
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(EmailListTableViewController.addRecipient(_:)))

        settings = realm.objects(Settings.self)[0] as Settings
        
        refreshData()
    }
    
    func refreshData() {
        recipList = []
        for recip in settings.emailList {
            recipList.append(recip.string)
        }

        recipList.sort {
            return $0.lowercased() < $1.lowercased()
        }
        for row in 0 ..< tableView.numberOfRows(inSection: 0) {
            tableView.deselectRow(at: IndexPath(row: row, section: 0), animated: true)
        }
    }

    
    //-------------------------------
    // MARK: - Table view data source
    //-------------------------------

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath) as UITableViewCell!
        
        cell?.textLabel?.text = recipList[indexPath.row]

        return cell!
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.recipList.count
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            for recipNum in 0 ..< settings.emailList.count {
                if settings.emailList[recipNum].string == recipList[indexPath.row] {
                    try! realm.write {
                        self.settings.emailList.remove(objectAtIndex: recipNum)
                    }
                    break
                }
            }
            refreshData()
        }  
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performEditingAtIndexPath(indexPath)
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
       
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Delete") { (Action) in
            self.removeStringAtIndexPath(indexPath)
        }
        
        let editAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: "Edit") { (Action) in
            self.performEditingAtIndexPath(indexPath)
        }
        
        editAction.backgroundColor = .blueTintColor()
        
        return [deleteAction, editAction]
    }

    func performEditingAtIndexPath(_ indexPath: IndexPath) {
        print(self.recipList)
        let alert = UIAlertController(title: "Recipient", message: nil, preferredStyle: .alert)

        alert.addTextField(configurationHandler: {(textField: UITextField!) in
            textField.keyboardType = .emailAddress
            textField.placeholder = "Email"
            textField.text = self.recipList[indexPath.row]
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel){
            (Action) in
            self.tableView.setEditing(false, animated: true)
            self.refreshData()
        })

        alert.addAction(UIAlertAction(title: "Save", style: .default) { Action in
            self.removeStringAtIndexPath(indexPath)

            var textFields = alert.textFields as [UITextField]!
            self.insertString((textFields?[0].text!)!)

            self.tableView.setEditing(false, animated: true)
        })

        self.present(alert, animated: true, completion: nil)
    }

    func removeStringAtIndexPath(_ indexPath: IndexPath){
        try! self.realm.write {
            self.settings.emailList.remove(objectAtIndex: indexPath.row)
        }
        self.recipList.remove(at: indexPath.row)
        self.tableView.deleteRows(at: [indexPath], with: .fade)
        self.refreshData()
    }

    //---------------------------------------
    // MARK: - Handling Addition of addresses
    //---------------------------------------

    func insertString(_ string: String){
        if let _ = string.range(of: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}", options: .regularExpression)  {
            let emailString = EmailString(string: string)
            let ind = self.recipList.insertionIndexOf(string, isOrderedBefore: {return $0 < $1})
            try! self.realm.write {
                self.settings.emailList.insert(emailString, at: ind)
            }
            self.recipList.insert(string, at: ind)
            self.tableView.insertRows(at: [IndexPath(row: ind, section: 0)], with: .fade)
            self.refreshData()
        } else {
            presentRecipientGetEmailFailedController(string)
        }
    }

    func presentRecipientGetEmailFailedController(_ string: String) {
        let alert = UIAlertController(title: "Recipient", message: "'\(string)'\nIs not a valid email address.", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        alert.addAction(UIAlertAction(title: "Try Again", style: .default) { Action in
            self.presentRecipientGetEmailController(string)
            })

        self.present(alert, animated: true, completion: nil)
    }

    func presentRecipientGetEmailController(_ string: String?) {
        let alert = UIAlertController(title: "Recipient", message: nil, preferredStyle: .alert)

        alert.addTextField(configurationHandler: {(textField: UITextField!) in
            textField.keyboardType = UIKeyboardType.emailAddress
            textField.placeholder = "Email"
            if string != nil {
                textField.text = string
            }
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        alert.addAction(UIAlertAction(title: "Save", style: .default) { Action in
            var textFields = alert.textFields as [UITextField]!
            self.insertString((textFields?[0].text!)!)
            })

        self.present(alert, animated: true, completion: nil)
    }
}

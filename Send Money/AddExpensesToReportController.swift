//
//  AddExpensesToReportController.swift
//  Send Money
//
//  Created by Eric Marshall on 7/29/15.
//  Copyright (c) 2015 Eric Marshall. All rights reserved.
//

import UIKit
import RealmSwift

class AddExpensesToReportController: UITableViewController {

    @IBAction func cancel(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("unwindToReportSegue", sender: self)
    }
    
    @IBAction func commit(sender: UIBarButtonItem) {
        for row in selectedRows {
            try! realm.write {
                let expense = self.realm.objectForPrimaryKey(Expense.self, key: self.expenseList[row].id)
                expense?.reportID = self.selectedReport.id
                self.realm.add(expense!, update: true)
            }
        }
        self.performSegueWithIdentifier("unwindToReportSegue", sender: self)
    }
    
    var expenseList: [Expense] = []
    var addButton: UIBarButtonItem!
    var selectedReport: Report!
    var selectedRows: [Int] = []
    var realm = try! Realm()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Get selected report
        let navC = self.navigationController as! IntermediateNavigationController
        selectedReport = realm.objectForPrimaryKey(Report.self, key: navC.selectedItemID)

        // Custom colors and sizes
        self.navigationController?.navigationBar.barTintColor = .greenTintColor()
        tableView.rowHeight = 84
        tableView.setEditing(true, animated: true)

        // Add navigation buttons
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: #selector(AddExpensesToReportController.cancel(_:)))
        self.navigationItem.setLeftBarButtonItem(cancelButton, animated: true)
        addButton = UIBarButtonItem(title: "Add", style: .Plain, target: self, action: #selector(AddExpensesToReportController.commit(_:)))
        self.navigationItem.setRightBarButtonItem(addButton, animated: true)
        self.navigationItem.title = "Add Expenses"

        // Get the available expenses
        let tmpexpenseList = realm.objects(Expense).filter("reportID=''")
        for expense in tmpexpenseList {
            expenseList.append(expense)
        }

        // Sort the list
        let df = NSDateFormatter()
        df.dateStyle = .MediumStyle
        expenseList.sortInPlace {
            if df.dateFromString($0.date)!.compare(df.dateFromString($1.date)!) == .OrderedSame {
                if $0.vendor == $1.vendor {
                    return $0.cost > $1.cost
                }
                return $0.vendor < $1.vendor
            }
            return df.dateFromString($0.date)!.compare(df.dateFromString($1.date)!) == .OrderedDescending
        }
        addButton.enabled = false
    }

    
    //-------------------------------
    // MARK: - Table view data source
    //-------------------------------

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
        if expenseList.count == 0 {
            messageLabel.text = "No expenses available to attach."
        }
        messageLabel.textColor = .lightGrayColor()
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = NSTextAlignment.Center
        messageLabel.font = UIFont.systemFontOfSize(20)
        messageLabel.sizeToFit()
        self.tableView.backgroundView = messageLabel;
        return expenseList.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("customExpenseCell", forIndexPath: indexPath) as! CustomExpenseViewCell

        let expense = expenseList[indexPath.row]
        
        cell.vendorLabel.text = expense.vendor
        cell.dateLabel.text = expense.date
        cell.reportLabel.text = ""
        cell.costLabel.text = expense.cost
        cell.costLabel.textColor = .blueTintColor()
        if expense.imageData.length != 0 {
            cell.expenseImage.image = UIImage(data: expense.imageData)
        }

        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if !addButton.enabled {
            addButton.enabled = true
        }
        selectedRows.append(indexPath.row)
        print(selectedRows)
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        for i in 0 ..< selectedRows.count {
            if selectedRows[i] == indexPath.row {
                selectedRows.removeAtIndex(i)
                break
            }
        }
        if selectedRows.count == 0 {
            addButton.enabled = false
        }
        print(selectedRows)
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if(self.tableView.respondsToSelector(Selector("setSeparatorInset:"))){
            self.tableView.separatorInset = UIEdgeInsetsZero
        }
        
        if(self.tableView.respondsToSelector(Selector("setLayoutMargins:"))){
            self.tableView.layoutMargins = UIEdgeInsetsZero
        }
        
        if(cell.respondsToSelector(Selector("setLayoutMargins:"))){
            cell.layoutMargins = UIEdgeInsetsZero
        }
    }
}

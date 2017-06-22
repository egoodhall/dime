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

    @IBAction func cancel(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "unwindToReportSegue", sender: self)
    }
    
    @IBAction func commit(_ sender: UIBarButtonItem) {
        for row in selectedRows {
            try! realm.write {
                let expense = self.realm.object(ofType: Expense.self, forPrimaryKey: self.expenseList[row].id)
                expense?.reportID = self.selectedReport.id
                self.realm.add(expense!, update: true)
            }
        }
        self.performSegue(withIdentifier: "unwindToReportSegue", sender: self)
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
        selectedReport = realm.object(ofType: Report.self, forPrimaryKey: navC.selectedItemID)

        // Custom colors and sizes
        self.navigationController?.navigationBar.barTintColor = .greenTintColor()
        tableView.rowHeight = 84
        tableView.setEditing(true, animated: true)

        // Add navigation buttons
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(AddExpensesToReportController.cancel(_:)))
        self.navigationItem.setLeftBarButton(cancelButton, animated: true)
        addButton = UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(AddExpensesToReportController.commit(_:)))
        self.navigationItem.setRightBarButton(addButton, animated: true)
        self.navigationItem.title = "Add Expenses"

        // Get the available expenses
        let tmpexpenseList = realm.objects(Expense.self).filter("reportID=''")
        for expense in tmpexpenseList {
            expenseList.append(expense)
        }

        // Sort the list
        let df = DateFormatter()
        df.dateStyle = .medium
        expenseList.sort {
            if df.date(from: $0.date)!.compare(df.date(from: $1.date)!) == .orderedSame {
                if $0.vendor == $1.vendor {
                    return $0.cost > $1.cost
                }
                return $0.vendor < $1.vendor
            }
            return df.date(from: $0.date)!.compare(df.date(from: $1.date)!) == .orderedDescending
        }
        addButton.isEnabled = false
    }

    
    //-------------------------------
    // MARK: - Table view data source
    //-------------------------------

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
        if expenseList.count == 0 {
            messageLabel.text = "No expenses available to attach."
        }
        messageLabel.textColor = .lightGray
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = NSTextAlignment.center
        messageLabel.font = UIFont.systemFont(ofSize: 20)
        messageLabel.sizeToFit()
        self.tableView.backgroundView = messageLabel;
        return expenseList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customExpenseCell", for: indexPath) as! CustomExpenseViewCell

        let expense = expenseList[indexPath.row]
        
        cell.vendorLabel.text = expense.vendor
        cell.dateLabel.text = expense.date
        cell.reportLabel.text = ""
        cell.costLabel.text = expense.cost
        cell.costLabel.textColor = .blueTintColor()
        if expense.imageData.count != 0 {
            cell.expenseImage.image = UIImage(data: expense.imageData as Data)
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !addButton.isEnabled {
            addButton.isEnabled = true
        }
        selectedRows.append(indexPath.row)
        print(selectedRows)
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        for i in 0 ..< selectedRows.count {
            if selectedRows[i] == indexPath.row {
                selectedRows.remove(at: i)
                break
            }
        }
        if selectedRows.count == 0 {
            addButton.isEnabled = false
        }
        print(selectedRows)
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if(self.tableView.responds(to: #selector(setter: UITableViewCell.separatorInset))){
            self.tableView.separatorInset = UIEdgeInsets.zero
        }
        
        if(self.tableView.responds(to: #selector(setter: UIView.layoutMargins))){
            self.tableView.layoutMargins = UIEdgeInsets.zero
        }
        
        if(cell.responds(to: #selector(setter: UIView.layoutMargins))){
            cell.layoutMargins = UIEdgeInsets.zero
        }
    }
}

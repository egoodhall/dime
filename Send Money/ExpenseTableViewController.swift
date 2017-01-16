//
//  FirstViewController.swift
//  Send Money
//
//  Created by Eric Marshall on 7/21/15.
//  Copyright (c) 2015 Eric Marshall. All rights reserved.
//

import UIKit
import RealmSwift

class ExpenseTableViewController: UITableViewController {

    /// A UISegmentedControl for choosing the ordering of Expenses
    @IBOutlet weak var expenseOrderControl: UISegmentedControl!

    /**
    Called when the user taps the "+" button to add a new expense
    
    - Parameter sender: The object which called the action
    */
    @IBAction func didPressAddButton(sender: AnyObject) {
        self.performSegueWithIdentifier("newExpenseModalSegue", sender: self)
    }

    /**
    Called when the UISegmentedControl's selected section changes
    
    - Parameter sender: The UISegmentedControl which called the action
    */
    @IBAction func expenseOrderControlDidChange(sender: UISegmentedControl) {
        refreshData()
        tableView.reloadData()
    }

    /// The default Realm
    var realm: Realm!
    /// The list of expenses in the Realm
    var expenseList: [Expense]! = []
    /// The list of reports in the Realm
    var reportList: [String : String] = [:]
    /// The Expense that has been selected in the UITableView
    var selectedItemID: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.barTintColor = UIColor.blueTintColor()
        self.navigationItem.leftBarButtonItem = nil
        self.navigationItem.title = "Expenses"
        expenseList = []
        tableView.rowHeight = 84
    }
    
    override func viewWillAppear(animated: Bool) {
        realm = try! Realm()
        refreshData()
        tableView.reloadData()
    }

    /// Called to update the badges on the UITabBarController
    func updateBadges() {
        var tabBarItems = self.tabBarController?.tabBar.items as [UITabBarItem]!
        let reports = realm.objects(Report).filter("status=\(ReportStatus.Open.rawValue)").count
        let expenses = realm.objects(Expense).filter("reportID=''").count
        if expenses == 0 {
            tabBarItems[0].badgeValue = nil
        } else {
            tabBarItems[0].badgeValue = "\(expenses)"
        }
        if reports == 0 {
            tabBarItems[1].badgeValue = nil
        } else {
            tabBarItems[1].badgeValue = "\(reports)"
        }
    }

    /// Called to refresh the items in the UITableView
    func refreshData() {
        expenseList = loadUnattachedExpenses()
        let availReports = realm.objects(Report).filter("status==\(ReportStatus.Open.rawValue)")
        reportList = [:]
        for realmReport in availReports {
            reportList[realmReport.id] = realmReport.name
        }
        let allExpenses = realm.objects(Expense)
        for key in Array(reportList.keys) {
            let expenses = allExpenses.filter("reportID='\(key)'")
            for expense in expenses {
                expenseList.append(expense)
            }
        }
        let df = NSDateFormatter()
        df.dateStyle = .MediumStyle
        switch (expenseOrderControl.selectedSegmentIndex) {
            case 0:
                expenseList.sortInPlace {
                    if df.dateFromString($0.date)!.compare(df.dateFromString($1.date)!) == .OrderedSame {
                        if $0.vendor.lowercaseString == $1.vendor.lowercaseString {
                            if $0.cost == $1.cost {
                                return self.reportList[$0.reportID] < self.reportList[$1.reportID]
                            }
                            return $0.cost > $1.cost
                        }
                        return $0.vendor.lowercaseString < $1.vendor.lowercaseString
                    }
                    return df.dateFromString($0.date)!.compare(df.dateFromString($1.date)!) == .OrderedDescending
                }
            case 1:
                expenseList.sortInPlace {
                    if $0.vendor.lowercaseString == $1.vendor.lowercaseString {
                        if self.reportList[$0.reportID] == self.reportList[$1.reportID] {
                            if df.dateFromString($0.date)!.compare(df.dateFromString($1.date)!) == .OrderedSame {
                                return $0.cost > $1.cost
                            }
                            return df.dateFromString($0.date)!.compare(df.dateFromString($1.date)!) == .OrderedDescending
                        }
                        return self.reportList[$0.reportID] < self.reportList[$1.reportID]
                    }
                    return $0.vendor.lowercaseString < $1.vendor.lowercaseString
                }
            case 2:
                expenseList.sortInPlace {
                    if self.reportList[$0.reportID] == self.reportList[$1.reportID] {
                        if $0.vendor.lowercaseString == $1.vendor.lowercaseString {
                            if df.dateFromString($0.date)!.compare(df.dateFromString($1.date)!) == .OrderedSame {
                                return $0.cost > $1.cost
                            }
                            return df.dateFromString($0.date)!.compare(df.dateFromString($1.date)!) == .OrderedDescending
                        }
                        return $0.vendor.lowercaseString < $1.vendor.lowercaseString
                    }
                    return self.reportList[$0.reportID] < self.reportList[$1.reportID]
                }
            default:
                break
        }
        updateBadges()
    }

    /**
    Loads all Expenses that aren't contained in reports
    
    :returns: [Expense]
    */
    func loadUnattachedExpenses() -> [Expense] {
        let unattachedExpenses = realm.objects(Expense).filter("reportID = ''")
        var expenses: [Expense] = []
        for expense in unattachedExpenses {
            expenses.append(expense)
        }
        return expenses
    }
    
    
    //-----------------------------
    // MARK: - TableView DataSource
    //-----------------------------

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
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CustomExpenseCell", forIndexPath: indexPath) as! CustomExpenseViewCell
        
        let expense = expenseList[indexPath.row]
        
        cell.vendorLabel.text = expense.vendor
        cell.dateLabel.text = expense.date
        if reportList[expense.reportID] != nil {
            cell.reportLabel.text = "'\(reportList[expense.reportID]!)'"
            cell.vendorLabel.textColor = .darkGrayColor()
        } else {
            cell.reportLabel.text = "Unreported"
            cell.vendorLabel.textColor = .darkTextColor()
            cell.backgroundColor = .whiteColor()
        }
        cell.costLabel.text = expense.cost
        cell.costLabel.textColor = .accentBlueColor()
        if expense.imageData.length != 0 {
            cell.expenseImage.image = UIImage(data: expense.imageData)
        } else {
            cell.expenseImage.image = UIImage(named: "addPhoto.png")
        }
        
        return cell
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
        if expenseList.count == 0 {
            messageLabel.text = "Tap '+' to create an Expense"
        }
        messageLabel.textColor = .lightGrayColor()
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = NSTextAlignment.Center
        messageLabel.font = UIFont.systemFontOfSize(20)
        messageLabel.sizeToFit()
        self.tableView.backgroundView = messageLabel;
        return expenseList.count
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedItemID = expenseList[indexPath.row].id
        self.performSegueWithIdentifier("editExpenseSegue", sender: self)
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch editingStyle {
            case .Delete:
                let delExpense = self.realm.objectForPrimaryKey(Expense.self, key: self.expenseList[indexPath.row].id)
                try! realm.write {
                    self.realm.delete(delExpense!)
                }
                refreshData()
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            default:
                break
        }
    } 
    

    //-------------------
    // MARK: - Navigation
    //-------------------
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "editExpenseSegue" {
            let destVC = segue.destinationViewController as! NewExpenseTableViewController
            destVC.selectedExpense = realm.objectForPrimaryKey(Expense.self, key: selectedItemID)
            destVC.hidesBottomBarWhenPushed = true
        }
    }
    
    @IBAction func saveExpenseSegue(sender: UIStoryboardSegue) {
        self.refreshData()
    }
    
    @IBAction func cancelExpenseSegue(sender: UIStoryboardSegue){
    }
}


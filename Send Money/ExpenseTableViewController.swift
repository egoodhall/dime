//
//  FirstViewController.swift
//  Send Money
//
//  Created by Eric Marshall on 7/21/15.
//  Copyright (c) 2015 Eric Marshall. All rights reserved.
//

import UIKit
import RealmSwift
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


class ExpenseTableViewController: UITableViewController {

    /// A UISegmentedControl for choosing the ordering of Expenses
    @IBOutlet weak var expenseOrderControl: UISegmentedControl!

    /**
    Called when the user taps the "+" button to add a new expense
    
    - Parameter sender: The object which called the action
    */
    @IBAction func didPressAddButton(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "newExpenseModalSegue", sender: self)
    }

    /**
    Called when the UISegmentedControl's selected section changes
    
    - Parameter sender: The UISegmentedControl which called the action
    */
    @IBAction func expenseOrderControlDidChange(_ sender: UISegmentedControl) {
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
    
    override func viewWillAppear(_ animated: Bool) {
        realm = try! Realm()
        refreshData()
        tableView.reloadData()
    }

    /// Called to update the badges on the UITabBarController
    func updateBadges() {
        var tabBarItems = self.tabBarController?.tabBar.items as [UITabBarItem]!
        let reports = realm.objects(Report.self).filter("status=\(ReportStatus.open.rawValue)").count
        let expenses = realm.objects(Expense.self).filter("reportID=''").count
        if expenses == 0 {
            tabBarItems?[0].badgeValue = nil
        } else {
            tabBarItems![0].badgeValue = "\(expenses)"
        }
        if reports == 0 {
            tabBarItems?[1].badgeValue = nil
        } else {
            tabBarItems![1].badgeValue = "\(reports)"
        }
    }

    /// Called to refresh the items in the UITableView
    func refreshData() {
        expenseList = loadUnattachedExpenses()
        let availReports = realm.objects(Report.self).filter("status==\(ReportStatus.open.rawValue)")
        reportList = [:]
        for realmReport in availReports {
            reportList[realmReport.id] = realmReport.name
        }
        let allExpenses = realm.objects(Expense.self)
        for key in Array(reportList.keys) {
            let expenses = allExpenses.filter("reportID='\(key)'")
            for expense in expenses {
                expenseList.append(expense)
            }
        }
        let df = DateFormatter()
        df.dateStyle = .medium
        switch (expenseOrderControl.selectedSegmentIndex) {
            case 0:
                expenseList.sort {
                    if df.date(from: $0.date)!.compare(df.date(from: $1.date)!) == .orderedSame {
                        if $0.vendor.lowercased() == $1.vendor.lowercased() {
                            if $0.cost == $1.cost {
                                return self.reportList[$0.reportID] < self.reportList[$1.reportID]
                            }
                            return $0.cost > $1.cost
                        }
                        return $0.vendor.lowercased() < $1.vendor.lowercased()
                    }
                    return df.date(from: $0.date)!.compare(df.date(from: $1.date)!) == .orderedDescending
                }
            case 1:
                expenseList.sort {
                    if $0.vendor.lowercased() == $1.vendor.lowercased() {
                        if self.reportList[$0.reportID] == self.reportList[$1.reportID] {
                            if df.date(from: $0.date)!.compare(df.date(from: $1.date)!) == .orderedSame {
                                return $0.cost > $1.cost
                            }
                            return df.date(from: $0.date)!.compare(df.date(from: $1.date)!) == .orderedDescending
                        }
                        return self.reportList[$0.reportID] < self.reportList[$1.reportID]
                    }
                    return $0.vendor.lowercased() < $1.vendor.lowercased()
                }
            case 2:
                expenseList.sort {
                    if self.reportList[$0.reportID] == self.reportList[$1.reportID] {
                        if $0.vendor.lowercased() == $1.vendor.lowercased() {
                            if df.date(from: $0.date)!.compare(df.date(from: $1.date)!) == .orderedSame {
                                return $0.cost > $1.cost
                            }
                            return df.date(from: $0.date)!.compare(df.date(from: $1.date)!) == .orderedDescending
                        }
                        return $0.vendor.lowercased() < $1.vendor.lowercased()
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
        let unattachedExpenses = realm.objects(Expense.self).filter("reportID = ''")
        var expenses: [Expense] = []
        for expense in unattachedExpenses {
            expenses.append(expense)
        }
        return expenses
    }
    
    
    //-----------------------------
    // MARK: - TableView DataSource
    //-----------------------------

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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomExpenseCell", for: indexPath) as! CustomExpenseViewCell
        
        let expense = expenseList[indexPath.row]
        
        cell.vendorLabel.text = expense.vendor
        cell.dateLabel.text = expense.date
        if reportList[expense.reportID] != nil {
            cell.reportLabel.text = "'\(reportList[expense.reportID]!)'"
            cell.vendorLabel.textColor = .darkGray
        } else {
            cell.reportLabel.text = "Unreported"
            cell.vendorLabel.textColor = .darkText
            cell.backgroundColor = .white
        }
        cell.costLabel.text = expense.cost
        cell.costLabel.textColor = .accentBlueColor()
        if expense.imageData.count != 0 {
            cell.expenseImage.image = UIImage(data: expense.imageData as Data)
        } else {
            cell.expenseImage.image = UIImage(named: "addPhoto.png")
        }
        
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
        if expenseList.count == 0 {
            messageLabel.text = "Tap '+' to create an Expense"
        }
        messageLabel.textColor = .lightGray
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = NSTextAlignment.center
        messageLabel.font = UIFont.systemFont(ofSize: 20)
        messageLabel.sizeToFit()
        self.tableView.backgroundView = messageLabel;
        return expenseList.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedItemID = expenseList[indexPath.row].id
        self.performSegue(withIdentifier: "editExpenseSegue", sender: self)
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
            case .delete:
                let delExpense = self.realm.object(ofType: Expense.self, forPrimaryKey: self.expenseList[indexPath.row].id)
                try! realm.write {
                    self.realm.delete(delExpense!)
                }
                refreshData()
                tableView.deleteRows(at: [indexPath], with: .automatic)
            default:
                break
        }
    } 
    

    //-------------------
    // MARK: - Navigation
    //-------------------
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editExpenseSegue" {
            let destVC = segue.destination as! NewExpenseTableViewController
            destVC.selectedExpense = realm.object(ofType: Expense.self, forPrimaryKey: selectedItemID)
            destVC.hidesBottomBarWhenPushed = true
        }
    }
    
    @IBAction func saveExpenseSegue(_ sender: UIStoryboardSegue) {
        self.refreshData()
    }
    
    @IBAction func cancelExpenseSegue(_ sender: UIStoryboardSegue){
    }
}


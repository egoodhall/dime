//
//  SecondViewController.swift
//  Send Money
//
//  Created by Eric Marshall on 7/21/15.
//  Copyright (c) 2015 Eric Marshall. All rights reserved.
//

import UIKit
import RealmSwift
import MessageUI


class ReportTableViewController: UITableViewController {
    
    @IBOutlet weak var reportStatusSelector: UISegmentedControl!
    
    @IBAction func didPressAddButton(sender: UIBarButtonItem) {
        let addReportAlert = UIAlertController(title: "Report", message: nil, preferredStyle: .Alert)
        addReportAlert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
            textField.placeholder = "Title"
            textField.textAlignment = .Center
            textField.autocapitalizationType = .Words
            }
        )
        addReportAlert.addAction(UIAlertAction(title: "Save", style: .Default) { (Action) in
            var textFields = addReportAlert.textFields as [UITextField]!
            if textFields[0].text != "" && textFields[0].text != nil{
                let report = Report()
                report.name = textFields[0].text!
                try! self.realm.write {
                    self.realm.add(report, update: false)
                }
                let ind = self.currentReportList.insertionIndexOf(report, isOrderedBefore: {
                    if $0.status == $1.status {
                        if $0.name == $1.name {
                            return $0.id < $0.id
                        }
                        return $0.name < $1.name
                    }
                    return $0.status < $1.status
                })
                self.currentReportList.insert(report, atIndex: ind)
                self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: ind, inSection: 0)], withRowAnimation: .Automatic)
                self.updateBadges()
            } else {
                let alert = UIAlertController(title: "Unable to Create Report", message: "The report's name must be at least 1 character", preferredStyle: .Alert)
                
                alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
                
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
        )
        addReportAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(addReportAlert, animated: true, completion: nil)
    }
    
    @IBAction func selectedSegmentDidChange(sender: UISegmentedControl) {
        refreshData()
        switch (reportStatusSelector.selectedSegmentIndex) {
            // Open Reports
            case 0:
                self.navigationItem.setRightBarButtonItem(UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(ReportTableViewController.didPressAddButton(_:))), animated: true)
                self.currentReportList = openReportList
                refreshData()
            // Submitted and Paid Reports
            default:
                self.navigationItem.setRightBarButtonItem(nil, animated: true)
                self.currentReportList = submittedReportList
                refreshData()
        }
    }
    
    let realm = try! Realm()
    var openReportList: [Report] = []
    var submittedReportList: [Report] = []
    var currentReportList: [Report]! = []
    var currencyFormatter = NSNumberFormatter()
    var selectedRow: Int!
    var selectedReport: Report!
    var createdFileName: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.barTintColor = UIColor.greenTintColor()
        
        tableView.rowHeight = 84
        selectedSegmentDidChange(reportStatusSelector)
        currencyFormatter.numberStyle = .CurrencyStyle
        currencyFormatter.locale = NSLocale(localeIdentifier: "en_US")
        currentReportList = openReportList
    }
    
    override func viewWillAppear(animated: Bool) {
        updatePaidReports()
        self.navigationController?.toolbarHidden = true
        refreshData()
        updateBadges()
    }
    
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
    
    func refreshData() {
        for row in 0 ..< self.tableView.numberOfRowsInSection(0) {
            self.tableView.deselectRowAtIndexPath(NSIndexPath(forRow: row, inSection: 0), animated: true)
        }
        openReportList = []
        submittedReportList = []
        let reports = realm.objects(Report)
        for report in reports {
            if report.status == ReportStatus.Open.rawValue {
                openReportList.append(report)
            } else {
                submittedReportList.append(report)
            }
        }
        switch reportStatusSelector.selectedSegmentIndex {
            case 0:
                currentReportList = openReportList
            case 1:
                currentReportList = submittedReportList
            default:
                break
        }
        
        currentReportList.sortInPlace {
            if $0.status == $1.status {
                if $0.deleteDateAndTime.isEqualToDate($1.deleteDateAndTime) {
                    if $0.name == $1.name {
                        return $0.id < $0.id
                    }
                    return $0.name < $1.name
                }
                return $0.deleteDateAndTime.compare($1.deleteDateAndTime) == .OrderedAscending
            }
            return $0.status < $1.status
        }
        tableView.reloadData()
        updateBadges()
    }
    
    func updatePaidReports() {
        if realm.objects(Settings)[0].deleteIntervalRow != 6 {
            let components = NSDateComponents()
            switch realm.objects(Settings)[0].deleteIntervalRow {
            case 0:
                components.day = 1
            case 1:
                components.day = 3
            case 2:
                components.day = 7
            case 3:
                components.day = 14
            case 4:
                components.day = 30
            case 5:
                components.day = 90
            default:
                fatalError("Report deletion delay should never get here")
            }
            let cal = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
            var reports: [Report] = []
            for report in realm.objects(Report).filter("status=\(ReportStatus.Paid.rawValue)") {
                reports.append(report)
            }
            for report in reports {
                let delDate = cal!.dateByAddingComponents(components, toDate: report.deleteDateAndTime, options: NSCalendarOptions.WrapComponents)
                let date = NSDate()
                if delDate!.laterDate(date) == date {
                    try! realm.write {
                        self.realm.delete( self.realm.objects(Expense).filter("reportID='\(report.id)'"))
                        self.realm.delete( self.realm.objectForPrimaryKey(Report.self, key: report.id)!)
                    }
                }
            }
        }
    }
    
    
    //-------------------------------
    // MARK: - Table view data source
    //-------------------------------
    
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
        switch reportStatusSelector.selectedSegmentIndex {
            case 0:
                let cell = tableView.dequeueReusableCellWithIdentifier("customOpenReportCell", forIndexPath: indexPath) as! OpenReportViewCell
                
                let report = currentReportList[indexPath.row]
                let expensesInReport = realm.objects(Expense).filter("reportID='\(report.id)'")
                
                cell.reportNameLabel.text = report.name
                var reportCost = 0.0
                var reportContent = ""
                if expensesInReport.count == 1 {
                    reportContent = "1 Expense"
                } else {
                    reportContent = "\(expensesInReport.count) Expenses"
                }
                if expensesInReport.count != 0 {
                    for i in 0 ..< expensesInReport.count {
                        reportCost += (NSString(string: expensesInReport[i].cost.stringByReplacingOccurrencesOfString("[^0-9]", withString: "", options: .RegularExpressionSearch, range: nil)).doubleValue / 100)
                    }
                }
                cell.reportContentLabel.text = reportContent
                cell.reportTotalLabel.text = currencyFormatter.stringFromNumber(NSNumber(double: reportCost))
                cell.reportTotalLabel.textColor = .greenTintColor()
                return cell
            default:
                let cell = tableView.dequeueReusableCellWithIdentifier("customSubmittedReportCell", forIndexPath: indexPath) as! SubmittedReportViewCell
                
                let report = currentReportList[indexPath.row]
                let expensesInReport = realm.objects(Expense).filter("reportID='\(report.id)'")
                cell.reportNameLabel.text = "\(report.name)"
                var reportCost = 0.0
                for i in 0 ..< expensesInReport.count {
                    reportCost += (NSString(string: expensesInReport[i].cost.stringByReplacingOccurrencesOfString("[^0-9]", withString: "", options: .RegularExpressionSearch, range: nil)).doubleValue / 100)
                }
                if report.status == ReportStatus.Submitted.rawValue {
                    cell.reportStatusImage.image = UIImage(named: "UnpaidIcon")
                    cell.reportStatusLabel.textColor = UIColor(red: 0.9, green: 0.0, blue: 0.0, alpha: 1.0)
                    cell.reportStatusLabel.text = "Unpaid"
                } else {
                    cell.reportStatusImage.image = UIImage(named: "PaidIcon")
                    cell.reportStatusLabel.textColor = .blueTintColor()
                    cell.reportStatusLabel.text = "Paid"
                }
                cell.reportTotalLabel.text = currencyFormatter.stringFromNumber(NSNumber(double: reportCost))
                cell.reportTotalLabel.textColor = .greenTintColor()
                return cell
        }

    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedRow = indexPath.row
        self.performSegueWithIdentifier("showReportSegue", sender: self)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
        if currentReportList.count == 0 && reportStatusSelector.selectedSegmentIndex == 0 {
            messageLabel.text = "Tap '+' to create a Report"
        }
        messageLabel.textColor = .lightGrayColor()
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = NSTextAlignment.Center
        messageLabel.font = UIFont.systemFontOfSize(20)
        messageLabel.sizeToFit()
        self.tableView.backgroundView = messageLabel;
        return currentReportList.count
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        switch currentReportList[indexPath.row].status {
            
        case ReportStatus.Open.rawValue:
            return [buildDeleteAction(forIndexPath: indexPath),
                    buildEditAction(forIndexPath: indexPath),
                    buildSubmitAction(forIndexPath: indexPath)]
            
        case ReportStatus.Submitted.rawValue:
            return [buildMarkPaidAction(forIndexPath: indexPath),
                    buildSubmitAction(forIndexPath: indexPath)]
            
        case ReportStatus.Paid.rawValue:
            return [buildSubmitAction(forIndexPath: indexPath)]
            
        default:
            return []
        }
    }
    
    private func buildDeleteAction(forIndexPath indexPath: NSIndexPath) -> UITableViewRowAction {
        let deleteAction = UITableViewRowAction(style: .Default, title: "Delete"){ (Action) in
            let report = self.currentReportList[indexPath.row]
            if self.realm.objects(Expense).filter("reportID='\(report.id)'").count > 0 {
                
                let alert = UIAlertController(title: "Delete", message: "Delete all Expenses in \(report.name)?", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Delete", style: .Destructive) { (Action) in
                    try! self.realm.write {
                        self.realm.delete(self.realm.objects(Expense).filter("reportID='\(report.id)'"))
                        self.realm.delete(self.currentReportList[indexPath.row])
                    }
                    self.currentReportList.removeAtIndex(indexPath.row)
                    self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                    self.updateBadges()
                    })
                
                alert.addAction(UIAlertAction(title: "Keep", style: .Default){ (Action) in
                    for expense in self.realm.objects(Expense) {
                        if expense.reportID == report.id {
                            try! self.realm.write {
                                expense.reportID = ""
                            }
                        }
                    }
                    try! self.realm.write {
                        self.realm.delete(self.currentReportList[indexPath.row])
                    }
                    self.currentReportList.removeAtIndex(indexPath.row)
                    self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                    self.updateBadges()
                    })
                
                self.presentViewController(alert, animated: true, completion: nil)
            } else {
                try! self.realm.write {
                    self.realm.delete(self.currentReportList[indexPath.row])
                }
                self.currentReportList.removeAtIndex(indexPath.row)
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                self.updateBadges()
            }
        }
        deleteAction.backgroundColor = .redTintColor()
        return deleteAction
    }
    
    private func buildEditAction(forIndexPath indexPath: NSIndexPath) -> UITableViewRowAction {
        let editAction = UITableViewRowAction(style: .Default, title: "Rename") { (Action) in
            let addReportAlert = UIAlertController(title: "Rename", message: "", preferredStyle: .Alert)
            addReportAlert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
                textField.placeholder = "Name"
                textField.text = self.currentReportList[indexPath.row].name
                textField.textAlignment = .Center
                textField.autocapitalizationType = .Words
            })
            addReportAlert.addAction(UIAlertAction(title: "Save", style: .Default) { (Action) in
                var textFields = addReportAlert.textFields as [UITextField]!
                try! self.realm.write {
                    self.currentReportList[indexPath.row].name = textFields[0].text!
                }
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Left)
                })
            addReportAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            self.presentViewController(addReportAlert, animated: true, completion: nil)
        }
        editAction.backgroundColor = .blueTintColor()
        return editAction
    }
    
    private func buildSubmitAction(forIndexPath indexPath: NSIndexPath) -> UITableViewRowAction {
        let submitAction = UITableViewRowAction(style: .Default, title: "Submit") { (Action) in
            if (self.reportStatusSelector.selectedSegmentIndex == ReportStatus.Open.rawValue) {
                let alert = UIAlertController(title: "Submit?", message: "Reports cannot be changed after they are submitted", preferredStyle: .Alert)
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                
                alert.addAction(UIAlertAction(title: "Submit", style: .Destructive){
                    (Action) in
                    self.selectedReport = self.currentReportList[indexPath.row]
                    self.sendMail()
                    self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Left)
                    self.updateBadges()
                    })
                
                self.presentViewController(alert, animated: true, completion: nil)
            } else {
                self.selectedReport = self.currentReportList[indexPath.row]
                self.sendMail()
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Left)
                self.updateBadges()
            }
        }
        submitAction.backgroundColor = .greenTintColor()
        return submitAction
    }
    
    private func buildMarkPaidAction(forIndexPath indexPath: NSIndexPath) -> UITableViewRowAction {
        let markPaidAction = UITableViewRowAction(style: .Default, title: "Paid?") { (Action) in
            let report = self.currentReportList[indexPath.row]
            try! self.realm.write {
                report.status = ReportStatus.Paid.rawValue
            }
            
            // Remove the report from the list
            self.currentReportList.removeAtIndex(indexPath.row)
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Left)
            
            // Calculate the new index of the report in the list (now that it's marked paid)
            let ind = self.currentReportList.insertionIndexOf(report, isOrderedBefore: {
                if $0.status == $1.status {
                    if $0.name == $1.name {
                        return $0.id < $0.id
                    }
                    return $0.name < $1.name
                }
                return $0.status < $1.status
            })
            self.updateBadges()
            
            // Add the report at the new index
            self.currentReportList.insert(report, atIndex: ind)
            self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: ind, inSection: 0)], withRowAnimation: .Right)
        }
        markPaidAction.backgroundColor = .blueTintColor()
        return markPaidAction
    }
    
    //-------------------------------
    // MARK: - Navigation
    //-------------------------------
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showReportSegue" {
            let destVC = segue.destinationViewController as! ReportDetailTableViewController
            destVC.selectedReport = currentReportList[selectedRow]
            destVC.hidesBottomBarWhenPushed = true
        }
    }
}


extension ReportTableViewController: MFMailComposeViewControllerDelegate {
    
    func sendMail() {
        let mailComposeViewController = configuredMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            self.presentViewController(mailComposeViewController, animated: true, completion: {
                UIApplication.sharedApplication().statusBarStyle = .LightContent
            })
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposeVC = MFMailComposeViewController()
        
        mailComposeVC.navigationBar.tintColor = .whiteColor()
        
        mailComposeVC.mailComposeDelegate = self
        
        let settings = realm.objects(Settings)[0]
        var recipients: [String] = []
        for recipient in settings.emailList {
            recipients.append(recipient.string)
        }
        mailComposeVC.setToRecipients(recipients)
        
        mailComposeVC.setSubject("Expense Report: \(selectedReport.name)")
        createdFileName = PDFGenerator.generatePDF(selectedReport)
        mailComposeVC.addAttachmentData(NSData(contentsOfFile: createdFileName)!, mimeType: "application/pdf", fileName: "\(selectedReport.name).pdf")
        
        return mailComposeVC
    }
    
    func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertController(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", preferredStyle: .Alert)
        sendMailErrorAlert.addAction(UIAlertAction(title: "Okay", style: .Default, handler: nil))
        self.presentViewController(sendMailErrorAlert, animated: true, completion: nil)
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
        
        if selectedReport.status == ReportStatus.Open.rawValue {
            if result == MFMailComposeResultSent || result == MFMailComposeResultSaved{
                try! self.realm.write {
                    self.selectedReport.status = ReportStatus.Submitted.rawValue
                }
            }
        }
        try! NSFileManager.defaultManager().removeItemAtPath(createdFileName!)
    }
}


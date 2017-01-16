//
//  ReportDetailTableViewController.swift
//  Send Money
//
//  Created by Eric Marshall on 7/26/15.
//  Copyright (c) 2015 Eric Marshall. All rights reserved.
//

import UIKit
import CoreGraphics
import CoreText
import RealmSwift
import MessageUI

class ReportDetailTableViewController: UITableViewController {
    
    @IBAction func didSelectAddButton(sender: AnyObject) {
        self.performSegueWithIdentifier("addExpensesToReportSegue", sender: self)
    }
    
    @IBAction func didSelectSubmitButton(sender: UIButton) {
        if selectedReport.status == ReportStatus.Open.rawValue {
            let alert = UIAlertController(title: "Submit?", message: "Reports cannot be changed after they are submitted", preferredStyle: .Alert)

            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            
            alert.addAction(UIAlertAction(title: "Submit", style: .Destructive){
                (Action) in
                self.sendMail()
            })
            
            self.presentViewController(alert, animated: true, completion: nil)
        } else {
            self.sendMail()
        }
    }
    
    @IBAction func didSelectDeleteButton(sender: UIBarButtonItem) {
        
        if self.selectedRows.count > 0{
        
            let deleteOptionsAlert = UIAlertController(title: "Delete", message: "Would you like to detach the expenses from this report or delete them permanently?", preferredStyle: .Alert)
            
            deleteOptionsAlert.addAction(UIAlertAction(title: "Delete", style: .Destructive){
                (Action) in
                for row in self.selectedRows {
                    try! self.realm.write {
                        self.realm.delete(self.realm.objectForPrimaryKey(Expense.self, key: self.expenseList[row].id)!)
                    }
                }
                self.deselectAll()
                self.refreshData()
                self.updateBars()
            })
        
            deleteOptionsAlert.addAction(UIAlertAction(title: "Detach", style: .Default){
                (Action) in
                for row in self.selectedRows {
                    try! self.realm.write {
                        self.realm.objectForPrimaryKey(Expense.self, key: self.expenseList[row].id)!.reportID = ""
                    }
                }
                self.deselectAll()
                self.refreshData()
                self.updateBars()
                })
            
            self.presentViewController(deleteOptionsAlert, animated: true, completion: nil)
        } else {
            self.deselectAll()
        }
    }
    
    @IBAction func didSelectReportTitle(sender: AnyObject) {
        let alert = UIAlertController(title: "Edit Report Name", message: "", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler {
            (textField) in
            textField.placeholder = "Report Name"
            textField.text = self.selectedReport.name
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Save", style: .Default) {
            (Action) in
            var textFields = alert.textFields as [UITextField]!
            try! self.realm.write {
                self.selectedReport.name = textFields[0].text!
            }
            self.refreshData()
        })
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func didSelectMarkPaidButton(sender: UIBarButtonItem) {
        try! realm.write {
            self.selectedReport.deleteDateAndTime = NSDate()
            self.selectedReport.status = ReportStatus.Paid.rawValue
        }
        updateBars()
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var reportTitle: UIButton!
    @IBOutlet weak var totalCostLabel: UILabel!
    @IBOutlet weak var totalCostView: TopLineView!
    @IBOutlet weak var totalLabel: UILabel!
    
    let realm = try! Realm()
    let nf = NSNumberFormatter()
    var selectedReport: Report!
    var expenseList: [Expense] = []
    var selectedRows: [Int] = []
    var selectedRow: Int!
    var defaultTabFrame: CGRect!
    var fontName = "Helvetica"
    var createdFileName: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        nf.locale = NSLocale(localeIdentifier: "en_US")
        nf.numberStyle = .CurrencyStyle
        
        if selectedReport.status == ReportStatus.Open.rawValue {
            let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(ReportDetailTableViewController.didSelectAddButton(_:)))
            self.navigationItem.setRightBarButtonItem(addButton, animated: true)
        } else {
            reportTitle.userInteractionEnabled = false
        }
        
        totalCostLabel.textColor = .greenTintColor()
        
        refreshData()
        updateBars()
    }
    
    override func viewWillAppear(animated: Bool) {
        
        self.navigationController?.navigationBar.barTintColor = .greenTintColor()
        tableView.reloadData()
        
        for i in 0 ..< tableView.numberOfRowsInSection(0) {
            tableView.deselectRowAtIndexPath(NSIndexPath(forRow: i, inSection: 0), animated: false)
        }
        

        refreshData()
        updateBars()
    }

    func updateBars() {
        if tableView.editing {
            let deleteButton = UIBarButtonItem(barButtonSystemItem: .Trash, target: self, action: #selector(ReportDetailTableViewController.didSelectDeleteButton(_:)))
            self.navigationItem.setRightBarButtonItem(deleteButton, animated: true)
        }
        else {
            if selectedReport.status == ReportStatus.Open.rawValue {
                let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(ReportDetailTableViewController.didSelectAddButton(_:)))
                self.navigationItem.setRightBarButtonItem(addButton, animated: true)
            }
        }
        if expenseList.count == 0 {
            submitButton.alpha = 0.0
            submitButton.userInteractionEnabled = false
        } else {
            submitButton.alpha = 1.0
            submitButton.userInteractionEnabled = true
        }
    }
    
    func refreshData() {
        reportTitle.setTitle(selectedReport.name, forState: .Normal)
        reportTitle.setTitle(selectedReport.name, forState: .Selected)
        
        var prevExpenseList = expenseList
        expenseList = []
        
        for expense in realm.objects(Expense).filter("reportID='\(selectedReport.id)'") {
            expenseList.append(expense)
        }
        let df = NSDateFormatter()
        df.dateStyle = .MediumStyle
        expenseList.sortInPlace {
            if $0.vendor == $1.vendor {
                if $0.cost == $1.cost {
                    if df.dateFromString($0.date)!.compare(df.dateFromString($1.date)!) == .OrderedSame {
                        return $0.id < $1.id
                    }
                    return df.dateFromString($0.date)!.compare(df.dateFromString($1.date)!) == .OrderedDescending
                }
                return $0.cost > $1.cost
            }
            return $0.vendor < $1.vendor
        }
        
        print("\(prevExpenseList.count) -> \(expenseList.count)")
        
        var indexPaths: [NSIndexPath] = []
        
        if prevExpenseList.count == expenseList.count {
            for i in 0 ..< expenseList.count {
                indexPaths.append(NSIndexPath(forRow: i, inSection: 0))
            }
            tableView.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
        }
        else if prevExpenseList.count > expenseList.count {
                for i in 0 ..< prevExpenseList.count {
                    if !expenseList.contains(prevExpenseList[i]){
                        indexPaths.append(NSIndexPath(forRow: i, inSection: 0))
                    }
                }
            tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
        }
        else {
            for i in 0 ..< expenseList.count {
                if !prevExpenseList.contains(expenseList[i]) {
                    indexPaths.append(NSIndexPath(forRow: i, inSection: 0))
                }
            }
            tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
        }
        
        if expenseList.count > 0 {
            totalLabel.text = "Total:"
            var reportCost = 0.0
            for i in 0 ..< expenseList.count {
                reportCost += (NSString(string: expenseList[i].cost.stringByReplacingOccurrencesOfString("[^0-9]", withString: "", options: .RegularExpressionSearch, range: nil)).doubleValue / 100)
            }
            totalCostLabel.text = nf.stringFromNumber(reportCost)!
        } else {
            totalCostLabel.text = ""
            totalLabel.text = ""
        }
    }
    
    func deselectAll() {
        for i in 0 ..< expenseList.count {
            tableView.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: 0))?.setSelected(false, animated: true)
        }
        selectedRows = []
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
            if selectedReport.status == ReportStatus.Open.rawValue {
                messageLabel.text = "Tap '+' to add Expenses to the current Report."
            } else {
                messageLabel.text = "No Expenses to display"
            }
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
        cell.costLabel.textColor = .accentBlueColor()
        if expense.imageData.length != 0 {
            cell.expenseImage.image = UIImage(data: expense.imageData)
        }
        
        
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if selectedReport.status != ReportStatus.Open.rawValue {
            return false
        }
        return true
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if tableView.editing {
            selectedRows.append(indexPath.row)
        } else {
            selectedRow = indexPath.row
            self.performSegueWithIdentifier("didSelectExpenseSegue", sender: self)
        }
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if tableView.editing {
            for i in 0 ..< selectedRows.count {
                if selectedRows[i] == indexPath.row {
                    selectedRows.removeAtIndex(i)
                    break
                }
            }
        }
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
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        if selectedReport.status == ReportStatus.Open.rawValue {
            
            let deleteAction = UITableViewRowAction(style: .Default, title: "Delete"){ Action in
                self.selectedRows.append(indexPath.row)
                for row in self.selectedRows {
                    try! self.realm.write {
                        self.realm.delete(self.realm.objectForPrimaryKey(Expense.self, key: self.expenseList[row].id)!)
                    }
                }
                self.deselectAll()
                self.refreshData()
                self.updateBars()
            }
            
//            deleteAction.backgroundColor = .redTintColor()
            
            let detachAction = UITableViewRowAction(style: .Default, title: "Detach"){ Action in
                self.selectedRows.append(indexPath.row)
                for row in self.selectedRows {
                    try! self.realm.write {
                        self.realm.objectForPrimaryKey(Expense.self, key: self.expenseList[row].id)!.reportID = ""
                    }
                }
                self.deselectAll()
                self.refreshData()
                self.updateBars()
            }
            
            detachAction.backgroundColor = .blueTintColor()
            
            return [deleteAction, detachAction]
        }
        else {
            return nil
        }
    }


    //-------------------
    // MARK: - Navigation
    //-------------------

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "didSelectExpenseSegue" {
            let destVC = segue.destinationViewController as! NewExpenseTableViewController
            destVC.selectedExpense = self.realm.objectForPrimaryKey(Expense.self, key: expenseList[selectedRow].id)
        } else if segue.identifier == "addExpensesToReportSegue" {
            let destVC = segue.destinationViewController as! IntermediateNavigationController
            destVC.selectedItemID = selectedReport.id
        }
    }
    
    @IBAction func unwindToReportSegue(sender: UIStoryboardSegue) {
        refreshData()
        updateBars()
    }
}


extension ReportDetailTableViewController: MFMailComposeViewControllerDelegate {
    
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
        sendMailErrorAlert.addAction(UIAlertAction(title: "Okay", style: .Default) {
            (Action) in
            self.navigationController?.popToRootViewControllerAnimated(true)
            })
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
        do {
            try NSFileManager.defaultManager().removeItemAtPath(createdFileName!)
        } catch {
            print(error)
        }
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
}


class TopLineView: UIView {
    
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        CGContextSetRGBFillColor(context, 0.9, 0.9, 0.9, 1.0)
        CGContextFillRect(context, CGRect(x: 0, y: 1, width: bounds.width, height: 1))
    }
}


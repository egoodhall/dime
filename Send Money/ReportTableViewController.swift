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
    
    @IBAction func didPressAddButton(_ sender: UIBarButtonItem) {
        let addReportAlert = UIAlertController(title: "Report", message: nil, preferredStyle: .alert)
        addReportAlert.addTextField(configurationHandler: {(textField: UITextField!) in
            textField.placeholder = "Title"
            textField.textAlignment = .center
            textField.autocapitalizationType = .words
            }
        )
        addReportAlert.addAction(UIAlertAction(title: "Save", style: .default) { (Action) in
            var textFields = addReportAlert.textFields as [UITextField]!
            if textFields?[0].text != "" && textFields?[0].text != nil{
                let report = Report()
                report.name = (textFields?[0].text!)!
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
                self.currentReportList.insert(report, at: ind)
                self.tableView.insertRows(at: [IndexPath(row: ind, section: 0)], with: .automatic)
                self.updateBadges()
            } else {
                let alert = UIAlertController(title: "Unable to Create Report", message: "The report's name must be at least 1 character", preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                
                self.present(alert, animated: true, completion: nil)
            }
        }
        )
        addReportAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(addReportAlert, animated: true, completion: nil)
    }
    
    @IBAction func selectedSegmentDidChange(_ sender: UISegmentedControl) {
        refreshData()
        switch (reportStatusSelector.selectedSegmentIndex) {
            // Open Reports
            case 0:
                self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(ReportTableViewController.didPressAddButton(_:))), animated: true)
                self.currentReportList = openReportList
                refreshData()
            // Submitted and Paid Reports
            default:
                self.navigationItem.setRightBarButton(nil, animated: true)
                self.currentReportList = submittedReportList
                refreshData()
        }
    }
    
    let realm = try! Realm()
    var openReportList: [Report] = []
    var submittedReportList: [Report] = []
    var currentReportList: [Report]! = []
    var currencyFormatter = NumberFormatter()
    var selectedRow: Int!
    var selectedReport: Report!
    var createdFileName: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.barTintColor = UIColor.greenTintColor()
        
        tableView.rowHeight = 84
        selectedSegmentDidChange(reportStatusSelector)
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = Locale(identifier: "en_US")
        currentReportList = openReportList
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updatePaidReports()
        self.navigationController?.isToolbarHidden = true
        refreshData()
        updateBadges()
    }
    
    func updateBadges() {
        var tabBarItems = self.tabBarController?.tabBar.items as [UITabBarItem]!
        let reports = realm.objects(Report.self).filter("status=\(ReportStatus.open.rawValue)").count
        let expenses = realm.objects(Expense.self).filter("reportID=''").count
        if expenses == 0 {
            tabBarItems?[0].badgeValue = nil
        } else {
            tabBarItems?[0].badgeValue = "\(expenses)"
        }
        if reports == 0 {
            tabBarItems?[1].badgeValue = nil
        } else {
            tabBarItems?[1].badgeValue = "\(reports)"
        }
    }
    
    func refreshData() {
        for row in 0 ..< self.tableView.numberOfRows(inSection: 0) {
            self.tableView.deselectRow(at: IndexPath(row: row, section: 0), animated: true)
        }
        openReportList = []
        submittedReportList = []
        let reports = realm.objects(Report.self)
        for report in reports {
            if report.status == ReportStatus.open.rawValue {
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
        
        currentReportList.sort {
            if $0.status == $1.status {
                if $0.deleteDateAndTime == $1.deleteDateAndTime {
                    if $0.name == $1.name {
                        return $0.id < $0.id
                    }
                    return $0.name < $1.name
                }
                return $0.deleteDateAndTime.compare($1.deleteDateAndTime as Date) == .orderedAscending
            }
            return $0.status < $1.status
        }
        tableView.reloadData()
        updateBadges()
    }
    
    func updatePaidReports() {
        if realm.objects(Settings.self)[0].deleteIntervalRow != 6 {
            var components = DateComponents()
            switch realm.objects(Settings.self)[0].deleteIntervalRow {
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
            let cal = Calendar(identifier: Calendar.Identifier.gregorian)
            var reports: [Report] = []
            for report in realm.objects(Report.self).filter("status=\(ReportStatus.paid.rawValue)") {
                reports.append(report)
            }
            for report in reports {
                let delDate = (cal as NSCalendar).date(byAdding: components, to: report.deleteDateAndTime as Date, options: NSCalendar.Options.wrapComponents)
                let date = Date()
                if (delDate! as NSDate).laterDate(date) == date {
                    try! realm.write {
                        self.realm.delete( self.realm.objects(Expense.self).filter("reportID='\(report.id)'"))
                        self.realm.delete( self.realm.object(ofType: Report.self, forPrimaryKey: report.id)!)

                    }
                }
            }
        }
    }
    
    
    //-------------------------------
    // MARK: - Table view data source
    //-------------------------------
    
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
        switch reportStatusSelector.selectedSegmentIndex {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "customOpenReportCell", for: indexPath) as! OpenReportViewCell
                
                let report = currentReportList[indexPath.row]
                let expensesInReport = realm.objects(Expense.self).filter("reportID='\(report.id)'")
                
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
                        reportCost += (NSString(string: expensesInReport[i].cost.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression, range: nil)).doubleValue / 100)
                    }
                }
                cell.reportContentLabel.text = reportContent
                cell.reportTotalLabel.text = currencyFormatter.string(from: NSNumber(value: reportCost as Double))
                cell.reportTotalLabel.textColor = .greenTintColor()
                return cell
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "customSubmittedReportCell", for: indexPath) as! SubmittedReportViewCell
                
                let report = currentReportList[indexPath.row]
                let expensesInReport = realm.objects(Expense.self).filter("reportID='\(report.id)'")
                cell.reportNameLabel.text = "\(report.name)"
                var reportCost = 0.0
                for i in 0 ..< expensesInReport.count {
                    reportCost += (NSString(string: expensesInReport[i].cost.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression, range: nil)).doubleValue / 100)
                }
                if report.status == ReportStatus.submitted.rawValue {
                    cell.reportStatusImage.image = UIImage(named: "UnpaidIcon")
                    cell.reportStatusLabel.textColor = UIColor(red: 0.9, green: 0.0, blue: 0.0, alpha: 1.0)
                    cell.reportStatusLabel.text = "Unpaid"
                } else {
                    cell.reportStatusImage.image = UIImage(named: "PaidIcon")
                    cell.reportStatusLabel.textColor = .blueTintColor()
                    cell.reportStatusLabel.text = "Paid"
                }
                cell.reportTotalLabel.text = currencyFormatter.string(from: NSNumber(value: reportCost as Double))
                cell.reportTotalLabel.textColor = .greenTintColor()
                return cell
        }

    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedRow = indexPath.row
        self.performSegue(withIdentifier: "showReportSegue", sender: self)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
        if currentReportList.count == 0 && reportStatusSelector.selectedSegmentIndex == 0 {
            messageLabel.text = "Tap '+' to create a Report"
        }
        messageLabel.textColor = .lightGray
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = NSTextAlignment.center
        messageLabel.font = UIFont.systemFont(ofSize: 20)
        messageLabel.sizeToFit()
        self.tableView.backgroundView = messageLabel;
        return currentReportList.count
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        switch currentReportList[indexPath.row].status {
            
        case ReportStatus.open.rawValue:
            return [buildDeleteAction(forIndexPath: indexPath),
                    buildEditAction(forIndexPath: indexPath),
                    buildSubmitAction(forIndexPath: indexPath)]
            
        case ReportStatus.submitted.rawValue:
            return [buildMarkPaidAction(forIndexPath: indexPath),
                    buildSubmitAction(forIndexPath: indexPath)]
            
        case ReportStatus.paid.rawValue:
            return [buildSubmitAction(forIndexPath: indexPath)]
            
        default:
            return []
        }
    }
    
    fileprivate func buildDeleteAction(forIndexPath indexPath: IndexPath) -> UITableViewRowAction {
        let deleteAction = UITableViewRowAction(style: .default, title: "Delete"){ (Action) in
            let report = self.currentReportList[indexPath.row]
            if self.realm.objects(Expense.self).filter("reportID='\(report.id)'").count > 0 {
                
                let alert = UIAlertController(title: "Delete", message: "Delete all Expenses in \(report.name)?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { (Action) in
                    try! self.realm.write {
                        self.realm.delete(self.realm.objects(Expense.self).filter("reportID='\(report.id)'"))
                        self.realm.delete(self.currentReportList[indexPath.row])
                    }
                    self.currentReportList.remove(at: indexPath.row)
                    self.tableView.deleteRows(at: [indexPath], with: .automatic)
                    self.updateBadges()
                    })
                
                alert.addAction(UIAlertAction(title: "Keep", style: .default){ (Action) in
                    for expense in self.realm.objects(Expense.self) {
                        if expense.reportID == report.id {
                            try! self.realm.write {
                                expense.reportID = ""
                            }
                        }
                    }
                    try! self.realm.write {
                        self.realm.delete(self.currentReportList[indexPath.row])
                    }
                    self.currentReportList.remove(at: indexPath.row)
                    self.tableView.deleteRows(at: [indexPath], with: .automatic)
                    self.updateBadges()
                    })
                
                self.present(alert, animated: true, completion: nil)
            } else {
                try! self.realm.write {
                    self.realm.delete(self.currentReportList[indexPath.row])
                }
                self.currentReportList.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
                self.updateBadges()
            }
        }
        deleteAction.backgroundColor = .redTintColor()
        return deleteAction
    }
    
    fileprivate func buildEditAction(forIndexPath indexPath: IndexPath) -> UITableViewRowAction {
        let editAction = UITableViewRowAction(style: .default, title: "Rename") { (Action) in
            let addReportAlert = UIAlertController(title: "Rename", message: "", preferredStyle: .alert)
            addReportAlert.addTextField(configurationHandler: {(textField: UITextField!) in
                textField.placeholder = "Name"
                textField.text = self.currentReportList[indexPath.row].name
                textField.textAlignment = .center
                textField.autocapitalizationType = .words
            })
            addReportAlert.addAction(UIAlertAction(title: "Save", style: .default) { (Action) in
                var textFields = addReportAlert.textFields as [UITextField]!
                try! self.realm.write {
                    self.currentReportList[indexPath.row].name = (textFields?[0].text!)!
                }
                self.tableView.reloadRows(at: [indexPath], with: .left)
                })
            addReportAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(addReportAlert, animated: true, completion: nil)
        }
        editAction.backgroundColor = .blueTintColor()
        return editAction
    }
    
    fileprivate func buildSubmitAction(forIndexPath indexPath: IndexPath) -> UITableViewRowAction {
        let submitAction = UITableViewRowAction(style: .default, title: "Submit") { (Action) in
            if (self.reportStatusSelector.selectedSegmentIndex == ReportStatus.open.rawValue) {
                let alert = UIAlertController(title: "Submit?", message: "Reports cannot be changed after they are submitted", preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                alert.addAction(UIAlertAction(title: "Submit", style: .destructive){
                    (Action) in
                    self.selectedReport = self.currentReportList[indexPath.row]
                    self.sendMail()
                    self.tableView.reloadRows(at: [indexPath], with: .left)
                    self.updateBadges()
                    })
                
                self.present(alert, animated: true, completion: nil)
            } else {
                self.selectedReport = self.currentReportList[indexPath.row]
                self.sendMail()
                self.tableView.reloadRows(at: [indexPath], with: .left)
                self.updateBadges()
            }
        }
        submitAction.backgroundColor = .greenTintColor()
        return submitAction
    }
    
    fileprivate func buildMarkPaidAction(forIndexPath indexPath: IndexPath) -> UITableViewRowAction {
        let markPaidAction = UITableViewRowAction(style: .default, title: "Paid?") { (Action) in
            let report = self.currentReportList[indexPath.row]
            try! self.realm.write {
                report.status = ReportStatus.paid.rawValue
            }
            
            // Remove the report from the list
            self.currentReportList.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .left)
            
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
            self.currentReportList.insert(report, at: ind)
            self.tableView.insertRows(at: [IndexPath(row: ind, section: 0)], with: .right)
        }
        markPaidAction.backgroundColor = .blueTintColor()
        return markPaidAction
    }
    
    //-------------------------------
    // MARK: - Navigation
    //-------------------------------
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showReportSegue" {
            let destVC = segue.destination as! ReportDetailTableViewController
            destVC.selectedReport = currentReportList[selectedRow]
            destVC.hidesBottomBarWhenPushed = true
        }
    }
}


extension ReportTableViewController: MFMailComposeViewControllerDelegate {
    
    func sendMail() {
        let mailComposeViewController = configuredMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposeViewController, animated: true, completion: {
                UIApplication.shared.statusBarStyle = .lightContent
            })
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposeVC = MFMailComposeViewController()
        
        mailComposeVC.navigationBar.tintColor = .white
        
        mailComposeVC.mailComposeDelegate = self
        
        let settings = realm.objects(Settings.self)[0]
        var recipients: [String] = []
        for recipient in settings.emailList {
            recipients.append(recipient.string)
        }
        mailComposeVC.setToRecipients(recipients)
        
        mailComposeVC.setSubject("Expense Report: \(selectedReport.name)")
        createdFileName = PDFGenerator.generatePDF(selectedReport)
        mailComposeVC.addAttachmentData(try! Data(contentsOf: URL(fileURLWithPath: createdFileName)), mimeType: "application/pdf", fileName: "\(selectedReport.name).pdf")
        
        return mailComposeVC
    }
    
    func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertController(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", preferredStyle: .alert)
        sendMailErrorAlert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        self.present(sendMailErrorAlert, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
        
        if selectedReport.status == ReportStatus.open.rawValue {
            if result == MFMailComposeResult.sent || result == MFMailComposeResult.saved{
                try! self.realm.write {
                    self.selectedReport.status = ReportStatus.submitted.rawValue
                }
            }
        }
        try! FileManager.default.removeItem(atPath: createdFileName!)
    }
}


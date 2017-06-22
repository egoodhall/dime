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
    
    @IBAction func didSelectAddButton(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "addExpensesToReportSegue", sender: self)
    }
    
    @IBAction func didSelectSubmitButton(_ sender: UIButton) {
        if selectedReport.status == ReportStatus.open.rawValue {
            let alert = UIAlertController(title: "Submit?", message: "Reports cannot be changed after they are submitted", preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            alert.addAction(UIAlertAction(title: "Submit", style: .destructive){
                (Action) in
                self.sendMail()
            })
            
            self.present(alert, animated: true, completion: nil)
        } else {
            self.sendMail()
        }
    }
    
    @IBAction func didSelectDeleteButton(_ sender: UIBarButtonItem) {
        
        if self.selectedRows.count > 0{
        
            let deleteOptionsAlert = UIAlertController(title: "Delete", message: "Would you like to detach the expenses from this report or delete them permanently?", preferredStyle: .alert)
            
            deleteOptionsAlert.addAction(UIAlertAction(title: "Delete", style: .destructive){
                (Action) in
                for row in self.selectedRows {
                    try! self.realm.write {
                        self.realm.delete(self.realm.object(ofType: Expense.self, forPrimaryKey: self.expenseList[row].id)!)
                    }
                }
                self.deselectAll()
                self.refreshData()
                self.updateBars()
            })
        
            deleteOptionsAlert.addAction(UIAlertAction(title: "Detach", style: .default){
                (Action) in
                for row in self.selectedRows {
                    try! self.realm.write {
                        self.realm.object(ofType: Expense.self, forPrimaryKey: self.expenseList[row].id)!.reportID = ""
                    }
                }
                self.deselectAll()
                self.refreshData()
                self.updateBars()
                })
            
            self.present(deleteOptionsAlert, animated: true, completion: nil)
        } else {
            self.deselectAll()
        }
    }
    
    @IBAction func didSelectReportTitle(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Edit Report Name", message: "", preferredStyle: .alert)
        alert.addTextField {
            (textField) in
            textField.placeholder = "Report Name"
            textField.text = self.selectedReport.name
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Save", style: .default) {
            (Action) in
            var textFields = alert.textFields as [UITextField]!
            try! self.realm.write {
                self.selectedReport.name = textFields![0].text!
            }
            self.refreshData()
        })
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func didSelectMarkPaidButton(_ sender: UIBarButtonItem) {
        try! realm.write {
            self.selectedReport.deleteDateAndTime = Date()
            self.selectedReport.status = ReportStatus.paid.rawValue
        }
        updateBars()
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var reportTitle: UIButton!
    @IBOutlet weak var totalCostLabel: UILabel!
    @IBOutlet weak var totalCostView: TopLineView!
    @IBOutlet weak var totalLabel: UILabel!
    
    let realm = try! Realm()
    let nf = NumberFormatter()
    var selectedReport: Report!
    var expenseList: [Expense] = []
    var selectedRows: [Int] = []
    var selectedRow: Int!
    var defaultTabFrame: CGRect!
    var fontName = "Helvetica"
    var createdFileName: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        nf.locale = Locale(identifier: "en_US")
        nf.numberStyle = .currency
        
        if selectedReport.status == ReportStatus.open.rawValue {
            let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(ReportDetailTableViewController.didSelectAddButton(_:)))
            self.navigationItem.setRightBarButton(addButton, animated: true)
        } else {
            reportTitle.isUserInteractionEnabled = false
        }
        
        totalCostLabel.textColor = .greenTintColor()
        
        refreshData()
        updateBars()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        self.navigationController?.navigationBar.barTintColor = .greenTintColor()
        tableView.reloadData()
        
        for i in 0 ..< tableView.numberOfRows(inSection: 0) {
            tableView.deselectRow(at: IndexPath(row: i, section: 0), animated: false)
        }
        

        refreshData()
        updateBars()
    }

    func updateBars() {
        if tableView.isEditing {
            let deleteButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(ReportDetailTableViewController.didSelectDeleteButton(_:)))
            self.navigationItem.setRightBarButton(deleteButton, animated: true)
        }
        else {
            if selectedReport.status == ReportStatus.open.rawValue {
                let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(ReportDetailTableViewController.didSelectAddButton(_:)))
                self.navigationItem.setRightBarButton(addButton, animated: true)
            }
        }
        if expenseList.count == 0 {
            submitButton.alpha = 0.0
            submitButton.isUserInteractionEnabled = false
        } else {
            submitButton.alpha = 1.0
            submitButton.isUserInteractionEnabled = true
        }
    }
    
    func refreshData() {
        reportTitle.setTitle(selectedReport.name, for: UIControlState())
        reportTitle.setTitle(selectedReport.name, for: .selected)
        
        var prevExpenseList = expenseList
        expenseList = []
        
        for expense in realm.objects(Expense.self).filter("reportID='\(selectedReport.id)'") {
            expenseList.append(expense)
        }
        let df = DateFormatter()
        df.dateStyle = .medium
        expenseList.sort {
            if $0.vendor == $1.vendor {
                if $0.cost == $1.cost {
                    if df.date(from: $0.date)!.compare(df.date(from: $1.date)!) == .orderedSame {
                        return $0.id < $1.id
                    }
                    return df.date(from: $0.date)!.compare(df.date(from: $1.date)!) == .orderedDescending
                }
                return $0.cost > $1.cost
            }
            return $0.vendor < $1.vendor
        }
        
        print("\(prevExpenseList.count) -> \(expenseList.count)")
        
        var indexPaths: [IndexPath] = []
        
        if prevExpenseList.count == expenseList.count {
            for i in 0 ..< expenseList.count {
                indexPaths.append(IndexPath(row: i, section: 0))
            }
            tableView.reloadRows(at: indexPaths, with: .automatic)
        }
        else if prevExpenseList.count > expenseList.count {
                for i in 0 ..< prevExpenseList.count {
                    if !expenseList.contains(prevExpenseList[i]){
                        indexPaths.append(IndexPath(row: i, section: 0))
                    }
                }
            tableView.deleteRows(at: indexPaths, with: .automatic)
        }
        else {
            for i in 0 ..< expenseList.count {
                if !prevExpenseList.contains(expenseList[i]) {
                    indexPaths.append(IndexPath(row: i, section: 0))
                }
            }
            tableView.insertRows(at: indexPaths, with: .automatic)
        }
        
        if expenseList.count > 0 {
            totalLabel.text = "Total:"
            var reportCost = 0.0
            for i in 0 ..< expenseList.count {
                reportCost += (NSString(string: expenseList[i].cost.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression, range: nil)).doubleValue / 100)
            }
            totalCostLabel.text = nf.string(from: NSNumber(floatLiteral: reportCost))!
        } else {
            totalCostLabel.text = ""
            totalLabel.text = ""
        }
    }
    
    func deselectAll() {
        for i in 0 ..< expenseList.count {
            tableView.cellForRow(at: IndexPath(row: i, section: 0))?.setSelected(false, animated: true)
        }
        selectedRows = []
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
            if selectedReport.status == ReportStatus.open.rawValue {
                messageLabel.text = "Tap '+' to add Expenses to the current Report."
            } else {
                messageLabel.text = "No Expenses to display"
            }
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
        cell.costLabel.textColor = .accentBlueColor()
        if expense.imageData.count != 0 {
            cell.expenseImage.image = UIImage(data: expense.imageData as Data)
        }
        
        
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if selectedReport.status != ReportStatus.open.rawValue {
            return false
        }
        return true
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            selectedRows.append(indexPath.row)
        } else {
            selectedRow = indexPath.row
            self.performSegue(withIdentifier: "didSelectExpenseSegue", sender: self)
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            for i in 0 ..< selectedRows.count {
                if selectedRows[i] == indexPath.row {
                    selectedRows.remove(at: i)
                    break
                }
            }
        }
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
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        if selectedReport.status == ReportStatus.open.rawValue {
            
            let deleteAction = UITableViewRowAction(style: .default, title: "Delete"){ Action in
                self.selectedRows.append(indexPath.row)
                for row in self.selectedRows {
                    try! self.realm.write {
                        self.realm.delete(self.realm.object(ofType: Expense.self, forPrimaryKey: self.expenseList[row].id)!)
                    }
                }
                self.deselectAll()
                self.refreshData()
                self.updateBars()
            }
            
//            deleteAction.backgroundColor = .redTintColor()
            
            let detachAction = UITableViewRowAction(style: .default, title: "Detach"){ Action in
                self.selectedRows.append(indexPath.row)
                for row in self.selectedRows {
                    try! self.realm.write {
                        self.realm.object(ofType: Expense.self, forPrimaryKey: self.expenseList[row].id)!.reportID = ""
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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "didSelectExpenseSegue" {
            let destVC = segue.destination as! NewExpenseTableViewController
            destVC.selectedExpense = self.realm.object(ofType: Expense.self, forPrimaryKey: expenseList[selectedRow].id)
        } else if segue.identifier == "addExpensesToReportSegue" {
            let destVC = segue.destination as! IntermediateNavigationController
            destVC.selectedItemID = selectedReport.id
        }
    }
    
    @IBAction func unwindToReportSegue(_ sender: UIStoryboardSegue) {
        refreshData()
        updateBars()
    }
}


extension ReportDetailTableViewController: MFMailComposeViewControllerDelegate {
    
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
        sendMailErrorAlert.addAction(UIAlertAction(title: "Okay", style: .default) {
            (Action) in
            self.navigationController?.popToRootViewController(animated: true)
            })
        self.present(sendMailErrorAlert, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        if selectedReport.status == ReportStatus.open.rawValue {
            if result == MFMailComposeResult.saved || result == MFMailComposeResult.sent {
                try! self.realm.write {
                    self.selectedReport.status = ReportStatus.submitted.rawValue
                }
            }
        }
        do {
            try FileManager.default.removeItem(atPath: createdFileName!)
        } catch {
            print(error)
        }
        controller.dismiss(animated: true, completion: nil)
        self.navigationController?.popToRootViewController(animated: true)
    }
}


class TopLineView: UIView {
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        context?.fill(CGRect(x: 0, y: 1, width: bounds.width, height: 1))
    }
}


//
//  NewExpenseTableViewController.swift
//  
//
//  Created by Eric Marshall on 7/21/15.
//
//

import UIKit
import RealmSwift
import Material

/**
A child of UITableViewController, used for getting and editing information
in an expense
*/
class NewExpenseTableViewController: UITableViewController {

    /// UITextField for editing and displaying the Expense's Vendor
    @IBOutlet weak var vendorField: UITextField!
    /// UITextField for editing and displaying the Expense's Cost
    @IBOutlet weak var costField: UITextField!
    /// UITextField for editing and displaying the Expense's Date
    @IBOutlet weak var dateField: UITextField!
    /// UITextField for editing and displaying the Expense's containing Report
    @IBOutlet weak var reportField: UITextField!
    /// UITextField for editing and displaying the Expense's Details
    @IBOutlet weak var detailField: UITextField!
    /// UIImageVIew for editing and displaying the Expense's Image
    @IBOutlet weak var expenseImage: UIImageView!
    /**
    Called when the user selects the expenseImage UIImageView
    - Decides what should be done based upon the state of the image
        held by the Expense

     @IBOutlet weak var categoryButton: MaterialButton!
     @IBOutlet weak var categoryButton: MaterialButton!
    - Parameter sender: The UIGestureRecognizer that recognizes the touch within the UIImageView
    */
    @IBAction func didSelectPhoto(_ sender: UIGestureRecognizer) {
        shouldSave = false
        if imageIsDefault && allowImageEditing {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Camera", style: .default){
                (Action) in
                self.getPhoto(true)
                })
            alert.addAction(UIAlertAction(title: "Photo Library", style: .default){
                (Action) in
                self.getPhoto(false)
                })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            
            self.present(alert, animated: true, completion:  {
                self.shouldSave = true
            })
        } else {
            self.performSegue(withIdentifier: "showImageSegue", sender: self)
        }
    }

    /**
    Called whenever the user edits the costField. Reformats the string within it.
    
    - Parameter sender: The UITextField that called the action
    */
    @IBAction func reformatCostField(_ sender: UITextField) {
        let num = (NSString(string: costField.text!.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression, range: nil)).doubleValue / 100)
        costField.text = currencyFormatter.string(from: NSNumber(floatLiteral: num))
    }

    /**
    Called whenever the user edits the costField. Reformats the string within it.

    - Parameter sender: The UITextField that called the action
    */
    @IBAction func didSelectCancelButton(_ sender: UIBarButtonItem) {
        shouldSave = false
        self.performSegue(withIdentifier: "cancelExpenseSegue", sender: self)
    }

    /**
    Called when the user selects the save button

    - Parameter sender: The UIBarButtonItem that called the action
    */
    @IBAction func didSelectExpenseSaveButton(_ sender: UIBarButtonItem) {
//        saveData()
        self.performSegue(withIdentifier: "saveExpenseSegue", sender: self)
    }

    /**
    Called when the user selects the cancel button

    - Parameter sender: The UIBarButtonItem that called the action
    */
    @IBAction func didSelectReportSaveButton(_ sender: UIBarButtonItem) {
//        saveData()
        self.navigationController?.popViewController(animated: true)
    }


    var kPreferredTextFieldToKeyboardOffset: CGFloat = 20.0
    var keyboardFrame: CGRect = CGRect.null
    var keyboardIsShowing: Bool = false
    weak var activeTextField: UITextField?

    /// A NSDateFormatter instance for use in formatting the dateField
    var dateFormatter = DateFormatter()
    /// A NSNumberFormatter instance for formatting the costField
    var currencyFormatter = NumberFormatter()
    /// A dictionary of Reports of the form - [Report ID : Report]
    var reports: [String : Report] = [:]
    /// A string meant to temporarily hold data in case the user wants to cancel
    var tempCancelString = ""
    /// The currently selected row in the reportPicker
    var reportPickerSelectedRow = 0
    /// The current image owned by the Expense
    var currentImage: Data!
    /// Whether or not the Expense's image is the default image
    var imageIsDefault = true
    /// The UIDatePicker used by dateField
    var datePicker: UIDatePicker!
    /// The UIPickerView used by reportField
    var reportPicker: UIPickerView!
    /// The IntermediateNavigationController that the NewExpenseTableViewController is embedded in
    var navC: IntermediateNavigationController!
    /// The selected Expense
    var selectedExpense: Expense!
    /// Whether or not the user can edit the image
    var allowImageEditing = true
    /// The containing View for the adBannerView
    var adFooterView: UITableViewHeaderFooterView?
    /// The Default Realm
    let realm = try! Realm()
    // Tells whether the user chose to cancel
    var shouldSave = true


    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.navC = self.navigationController as? IntermediateNavigationController
        
        performButtonSetup()
        performGenTextFieldSetup()
        performCostFieldSetup()
        performReportFieldSetup()
        performDateFieldSetup()
        
        vendorField.delegate = self
        if selectedExpense == nil {
            if navC.selectedItemID != nil {
                self.navigationController?.navigationBar.barTintColor = .greenTintColor()
                refreshData()
                let selectedExpense = realm.object(ofType: Expense.self, forPrimaryKey: navC.selectedItemID)
                let containingReport = realm.object(ofType: Report.self, forPrimaryKey: selectedExpense!.reportID)
                if containingReport != nil {
                    reportField.text = containingReport!.name
                    if containingReport?.status != ReportStatus.open.rawValue {
                        navigationItem.title = "View Expense"
                        costField.isUserInteractionEnabled = false
                        vendorField.isUserInteractionEnabled = false
                        dateField.isUserInteractionEnabled = false
                        reportField.isUserInteractionEnabled = false
                        detailField.isUserInteractionEnabled = false
                        allowImageEditing = false
                        self.navigationItem.setRightBarButton(nil, animated: true)
                    }
                }
            }
        }
        else {
            self.navigationController?.navigationBar.barTintColor = .greenTintColor()
            refreshData()
            let containingReport = realm.object(ofType: Report.self, forPrimaryKey: selectedExpense!.reportID)
            if containingReport != nil {
                reportField.text = containingReport!.name
                if containingReport?.status != ReportStatus.open.rawValue {
                    navigationItem.title = "View Expense"
                    costField.isUserInteractionEnabled = false
                    vendorField.isUserInteractionEnabled = false
                    dateField.isUserInteractionEnabled = false
                    reportField.isUserInteractionEnabled = false
                    detailField.isUserInteractionEnabled = false
                    allowImageEditing = false
                    self.navigationItem.setRightBarButton(nil, animated: true)
                }
            }
        }
        
        // Set colors for items in view
        self.navigationController?.navigationBar.barTintColor = .blueTintColor()
        costField.textColor = .accentBlueColor()
    }

    override func viewWillAppear(_ animated: Bool) {
        shouldSave = true
    }

    /**
    Create the buttons to be shown in the Navigaton Bar
    */
    func performButtonSetup() {
        dateFormatter.dateStyle = .medium
        currencyFormatter.numberStyle = NumberFormatter.Style.currency
        currencyFormatter.locale = Locale(identifier: "en_US")
        let items = realm.objects(Report.self).filter("status==\(ReportStatus.open.rawValue)")
        for realmReport in items {
            reports[realmReport.id] = realmReport
        }
        
        if navC == nil {
            self.navigationItem.title = "Expense"
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: nil)
        } else {
            self.navigationItem.title = "New Expense"
            let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.plain, target: self, action: #selector(NewExpenseTableViewController.didSelectCancelButton(_:)))
            self.navigationItem.setLeftBarButton(cancelButton, animated: true)
        }
        
        if navC != nil  {
            let saveButton = UIBarButtonItem(title: "Save", style: UIBarButtonItemStyle.plain, target: self, action: #selector(NewExpenseTableViewController.didSelectExpenseSaveButton(_:)))
            print("B")
            self.navigationItem.setRightBarButton(saveButton, animated: true)
        }
    }

    /**
    Perform all necessary setup for the costField
    */
    func performCostFieldSetup() {
        let costBar: UIToolbar = UIToolbar()
        costBar.barStyle = UIBarStyle.default
        costBar.isTranslucent = true
        costBar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.done, target: self, action: #selector(NewExpenseTableViewController.doneBar(_:)))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.done, target: self, action: #selector(NewExpenseTableViewController.cancelBar(_:)))
        costBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        costBar.isUserInteractionEnabled = true
        costField.inputAccessoryView = costBar
    }

    /**
    Perform all necessary setup for the dateField
    */
    func performDateFieldSetup() {
        dateField.tintColor = .clear
        dateField.text = dateFormatter.string(from: Date())
        datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(NewExpenseTableViewController.handleDatePicker(_:)), for: UIControlEvents.valueChanged)
        dateField.inputView = datePicker
        
        let dateBar: UIToolbar = UIToolbar()
        dateBar.barStyle = UIBarStyle.default
        dateBar.isTranslucent = true
        dateBar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(NewExpenseTableViewController.doneBar(_:)))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(NewExpenseTableViewController.cancelBar(_:)))
        dateBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        dateBar.isUserInteractionEnabled = true
        dateField.inputAccessoryView = dateBar
    }

    /**
    Perform all necessary setup for the reportField
    */
    func performReportFieldSetup() {
        reportField.tintColor = .clear
        reportPicker = UIPickerView()
        reportPicker.delegate = self
        reportPicker.dataSource = self
        reportField.text = ""
        reportPicker.selectRow(0, inComponent: 0, animated: false)
        reportField.inputView = reportPicker
        let reportBar: UIToolbar = UIToolbar()
        reportBar.barStyle = UIBarStyle.default
        reportBar.isTranslucent = true
        reportBar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(NewExpenseTableViewController.doneBar(_:)))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(NewExpenseTableViewController.cancelBar(_:)))
        reportBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        reportBar.isUserInteractionEnabled = true
        reportField.inputAccessoryView = reportBar
    }

    /**
    Get the row at which a report with a given ID is at in the reportPicker
    */
    func getRow(_ key: String) -> Int {
        for i in 0 ..< reports.count {
            if key == Array(reports.keys)[i] {
                return i
            }
        }
        return 0
    }

    /**
    Handler for datePicker

    - Parameter sender: The UIDatePicker calling the function
    */
    func handleDatePicker(_ sender: UIDatePicker) {
        dateField.text = dateFormatter.string(from: sender.date)
    }

    /**
    Handler for the Done Button on the input accessory view of the current text field
    
    - Parameter sender: The object calling the function
    */
    func doneBar(_ sender: AnyObject) {
        tableView.endEditing(true)
    }

    /**
    Handler for the Cancel Button on the input accessory view of the current text field

    - Parameter sender: The object calling the function
    */
    func cancelBar(_ sender: UIBarButtonItem) {
        for textField in [dateField, costField, reportField] {
            if (textField?.isFirstResponder)! {
                textField?.text = tempCancelString
                textField?.resignFirstResponder()
                break
            }
        }
    }

    /**
    Store the data in a textField before the user edits it, in case of cancellation

    - Parameter sender: The object calling the function
    */
    func storeCancelData(_ textField: UITextField) {
        tempCancelString = textField.text!
    }

    /**
    Enter any data that needs to be put into the textFields for the current expense
    */
    func refreshData() {
        if selectedExpense == nil {
            selectedExpense = realm.object(ofType: Expense.self, forPrimaryKey: navC.selectedItemID)
        }
        vendorField.text = selectedExpense.vendor
        costField.text = selectedExpense.cost
        dateField.text = selectedExpense.date
        detailField.text = selectedExpense.details
        datePicker.setDate(dateFormatter.date(from: selectedExpense.date)!, animated: false)
        reportField.text = reports[selectedExpense.reportID]?.name
        for i in 0 ..< reports.count {
            if reports[Array(reports.keys)[i]]!.id == selectedExpense.reportID {
                reportPicker.selectRow(i + 1, inComponent: 0, animated: true)
                reportField.text = reports[Array(reports.keys)[i]]!.name
                reportPickerSelectedRow = i + 1
            }
        }
        if UIImage(data: selectedExpense.imageData as Data) != UIImage(named: "addPhoto") && Data() != selectedExpense.imageData as Data {
            print("Image is not default.")
            imageIsDefault = false
            expenseImage.image = UIImage(data: selectedExpense.imageData as Data)
        }
    }

    /**
    Handler for the Done Button on the input accessory view of the current text field

    - Parameter fromCamera: Whether or not the photo will be from the camera
    */
    func getPhoto(_ fromCamera: Bool) {
        let imgPicker = UIImagePickerController()
        imgPicker.allowsEditing = true
        if fromCamera {
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera){
                imgPicker.sourceType = .camera
                imgPicker.showsCameraControls = true
            }
        } else {
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
                imgPicker.sourceType = .photoLibrary
            }
        }
        imgPicker.delegate = self
        imgPicker.allowsEditing = false
        shouldSave = false;
        self.present(imgPicker, animated: true, completion: nil)
    }

    /**
    Save current data before exiting
    */
    func saveData() {
        let newExpense = Expense()
        newExpense.vendor = vendorField.text!
        newExpense.cost = costField.text!
        print(newExpense.cost + "->" + costField.text!)
        newExpense.date = dateField.text!
        newExpense.details = detailField.text!
        newExpense.imageIsDefault = imageIsDefault
        if reportPickerSelectedRow == 0 {
            newExpense.reportID = ""
        } else {
            newExpense.reportID = Array(reports.keys)[reportPickerSelectedRow - 1]
        }
        if !imageIsDefault {
            newExpense.imageData = UIImageJPEGRepresentation(expenseImage.image!, 1.0)!
        }
        if navC == nil {
            print("\n-----> Updating expense \(newExpense.id)")
            newExpense.id = selectedExpense.id
            try! realm.write {
                self.realm.add(newExpense, update: true)
            }
        } else {
            print("\n-----> New Expense \(newExpense.id)")
            try! realm.write {
                self.realm.add(newExpense, update: false)
            }
        }
        self.selectedExpense = newExpense
        refreshData()
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

    //-------------------
    // MARK: - Navigation
    //-------------------
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showImageSegue" {
            let destVC = segue.destination as! ExpenseImageViewController
            destVC.image = expenseImage.image
            destVC.allowImageEditing = self.allowImageEditing
        }
    }
    
    @IBAction func doneWithImageSegue(_ sender: UIStoryboardSegue) {
    }
}


extension NewExpenseTableViewController {
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
//        UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: false)
    }
}


extension NewExpenseTableViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [String: Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            self.imageIsDefault = false
            
            let croppedImage = scaleAndRotateImage(pickedImage)
            
            //            let rotationCenter = CGPoint(x: croppedImage!.size.width / 2, y: croppedImage!.size.height / 2)
            
            //            var transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
            
            self.expenseImage.image = croppedImage
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func scaleAndRotateImage(_ image: UIImage) -> UIImage {
        let kMaxResolution: CGFloat = 640
        let imgRef: CGImage = image.cgImage!
        let width: CGFloat = CGFloat(imgRef.width)
        let height: CGFloat = CGFloat(imgRef.height)
        var transform: CGAffineTransform = CGAffineTransform.identity
        var bounds: CGRect = CGRect(x: 0, y: 0, width: width, height: height)
        if width > kMaxResolution || height > kMaxResolution {
            let ratio: CGFloat = width / height
            if ratio > 1 {
                bounds.size.width = kMaxResolution
                bounds.size.height = (bounds.size.width / ratio)
            }
            else {
                bounds.size.height = kMaxResolution
                bounds.size.width = (bounds.size.height * ratio)
            }
        }
        let scaleRatio: CGFloat = bounds.size.width / width
        let imageSize: CGSize = CGSize(width: CGFloat(imgRef.width), height: CGFloat(imgRef.height))
        var boundHeight: CGFloat
        let orient: UIImageOrientation = image.imageOrientation
        switch orient {
        case UIImageOrientation.up:
            transform = CGAffineTransform.identity
        case UIImageOrientation.upMirrored:
            transform = CGAffineTransform(translationX: imageSize.width, y: 0.0)
            transform = transform.scaledBy(x: -1.0, y: 1.0)
        case UIImageOrientation.down:
            transform = CGAffineTransform(translationX: imageSize.width, y: imageSize.height)
            transform = transform.rotated(by: CGFloat(Double.pi))
        case UIImageOrientation.downMirrored:
            transform = CGAffineTransform(translationX: 0.0, y: imageSize.height)
            transform = transform.scaledBy(x: 1.0, y: -1.0)
        case UIImageOrientation.leftMirrored:
            boundHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundHeight
            transform = CGAffineTransform(translationX: imageSize.height, y: imageSize.width)
            transform = transform.scaledBy(x: -1.0, y: 1.0)
            transform = transform.rotated(by: CGFloat(3.0 * .pi / 2.0))
        case UIImageOrientation.left:
            boundHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundHeight
            transform = CGAffineTransform(translationX: 0.0, y: imageSize.width)
            transform = transform.rotated(by: CGFloat(3.0 * .pi / 2.0))
        case UIImageOrientation.rightMirrored:
            boundHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundHeight
            transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
            transform = transform.rotated(by: CGFloat(.pi / 2.0))
        case UIImageOrientation.right:
            boundHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundHeight
            transform = CGAffineTransform(translationX: imageSize.height, y: 0.0)
            transform = transform.rotated(by: CGFloat(.pi / 2.0))
        }
        UIGraphicsBeginImageContext(bounds.size)
        let context: CGContext = UIGraphicsGetCurrentContext()!
        if orient == UIImageOrientation.right || orient == UIImageOrientation.left {
            context.scaleBy(x: -scaleRatio, y: scaleRatio)
            context.translateBy(x: -height, y: 0)
        }
        else {
            context.scaleBy(x: scaleRatio, y: -scaleRatio)
            context.translateBy(x: 0, y: -height)
        }
        context.concatenate(transform)
        UIGraphicsGetCurrentContext()?.draw(imgRef, in: CGRect(x: 0, y: 0, width: width, height: height))
        let imageCopy: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return imageCopy
    }
}


extension NewExpenseTableViewController:  UIPickerViewDataSource, UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        reportPickerSelectedRow = row
        if row == 0 {
            reportField.text = ""
        } else {
            reportField.text = reports[Array(reports.keys)[row - 1]]?.name
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return reports.count + 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if row == 0 {
            return "Unattached"
        }
        return reports[Array(reports.keys)[row - 1]]!.name
    }
}


extension NewExpenseTableViewController: UITextFieldDelegate {
    
    @IBAction func textFieldDidReturn(_ textField: UITextField!) {
        textField.resignFirstResponder()
        self.activeTextField = nil
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (self.activeTextField != nil)
        {
            self.activeTextField?.resignFirstResponder()
            self.activeTextField = nil
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if shouldSave {
            if selectedExpense == nil || selectedExpense.reportID == "" {
                print("Selected expense was nil")
                saveData()
            } else if let report = realm.object(ofType: Report.self, forPrimaryKey: selectedExpense.reportID) {
                if report.status == ReportStatus.open.rawValue {
                    print("Selected expense was not nil")
                    saveData()
                }
            }
        }
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    func performGenTextFieldSetup() {
        NotificationCenter.default.addObserver(self, selector: #selector(NewExpenseTableViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(NewExpenseTableViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        addTargetsToTextField(vendorField)
        addTargetsToTextField(costField)
        addTargetsToTextField(dateField)
        addTargetsToTextField(reportField)
        addTargetsToTextField(detailField)
    }
    
    func addTargetsToTextField(_ textField: UITextField) {
        textField.addTarget(self, action: #selector(NewExpenseTableViewController.textFieldDidReturn(_:)), for: .editingDidEndOnExit)
        textField.addTarget(self, action: #selector(UITextFieldDelegate.textFieldDidBeginEditing(_:)), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(NewExpenseTableViewController.storeCancelData(_:)), for: .editingDidBegin)
    }
    
    func keyboardWillShow(_ notification: Foundation.Notification) {
        self.keyboardIsShowing = true
        if let info = notification.userInfo {
            self.keyboardFrame = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            self.arrangeViewOffsetFromKeyboard()
        }
        
    }
    
    func keyboardWillHide(_ notification: Foundation.Notification) {
        self.keyboardIsShowing = false
        self.returnViewToInitialFrame()
    }
    
    func arrangeViewOffsetFromKeyboard() {
        let theApp: UIApplication = UIApplication.shared
        let windowView: UIView? = theApp.delegate!.window!
        if self.activeTextField != nil {
            let textFieldLowerPoint: CGPoint = CGPoint(x: self.activeTextField!.frame.origin.x, y: self.activeTextField!.frame.origin.y + self.activeTextField!.frame.size.height)
            
            let convertedTextFieldLowerPoint: CGPoint = self.view.convert(textFieldLowerPoint, to: windowView)
            
            let targetTextFieldLowerPoint: CGPoint = CGPoint(x: self.activeTextField!.frame.origin.x, y: self.keyboardFrame.origin.y - kPreferredTextFieldToKeyboardOffset)
            
            let targetPointOffset: CGFloat = targetTextFieldLowerPoint.y - convertedTextFieldLowerPoint.y
            let adjustedViewFrameCenter: CGPoint = CGPoint(x: self.view.center.x, y: self.view.center.y + targetPointOffset)
            
            if self.keyboardFrame.origin.y < (self.activeTextField!.frame.origin.y + 50) {
                UIView.animate(withDuration: 0.2, animations: {
                    self.view.center = adjustedViewFrameCenter
                })
            }
        }
    }
    
    func returnViewToInitialFrame() {
        let initialViewRect: CGRect = CGRect(x: 0.0, y: 0.0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        
        if (!initialViewRect.equalTo(self.view.frame))
        {
            UIView.animate(withDuration: 0.2, animations: {
                self.view.frame = initialViewRect
            });
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.activeTextField = textField
        
        if(self.keyboardIsShowing)
        {
            self.arrangeViewOffsetFromKeyboard()
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        doneBar(textField)
        return false
    }
}


class SplitViewCell: UITableViewCell {
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundView = SplitLineView()
        self.backgroundColor = .white
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.backgroundView = SplitLineView()
        self.backgroundColor = .white
    }
}

class BottomLineCell: UITableViewCell {
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundView = BottomLineView()
        self.backgroundColor = .white
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.backgroundView = BottomLineView()
        self.backgroundColor = .white
    }
}

class SplitLineView: UIView {
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        context?.fill(CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height))
        context?.setFillColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
        context?.fill(CGRect(x: bounds.width / 2, y: 0, width: 0.8, height: bounds.height))
    }
}

class BottomLineView: UIView {
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        context?.fill(CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height))
        context?.setFillColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.85)
        context?.fill(CGRect(x: 0, y: bounds.height - 1, width: bounds.width, height: 1))
    }
}

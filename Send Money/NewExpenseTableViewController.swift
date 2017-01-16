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
    @IBAction func didSelectPhoto(sender: UIGestureRecognizer) {
        shouldSave = false
        if imageIsDefault && allowImageEditing {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            
            alert.addAction(UIAlertAction(title: "Camera", style: .Default){
                (Action) in
                self.getPhoto(true)
                })
            alert.addAction(UIAlertAction(title: "Photo Library", style: .Default){
                (Action) in
                self.getPhoto(false)
                })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            
            
            self.presentViewController(alert, animated: true, completion:  {
                self.shouldSave = true
            })
        } else {
            self.performSegueWithIdentifier("showImageSegue", sender: self)
        }
    }

    /**
    Called whenever the user edits the costField. Reformats the string within it.
    
    - Parameter sender: The UITextField that called the action
    */
    @IBAction func reformatCostField(sender: UITextField) {
        let num = (NSString(string: costField.text!.stringByReplacingOccurrencesOfString("[^0-9]", withString: "", options: .RegularExpressionSearch, range: nil)).doubleValue / 100)
        costField.text = currencyFormatter.stringFromNumber(num)
    }

    /**
    Called whenever the user edits the costField. Reformats the string within it.

    - Parameter sender: The UITextField that called the action
    */
    @IBAction func didSelectCancelButton(sender: UIBarButtonItem) {
        shouldSave = false
        self.performSegueWithIdentifier("cancelExpenseSegue", sender: self)
    }

    /**
    Called when the user selects the save button

    - Parameter sender: The UIBarButtonItem that called the action
    */
    @IBAction func didSelectExpenseSaveButton(sender: UIBarButtonItem) {
//        saveData()
        self.performSegueWithIdentifier("saveExpenseSegue", sender: self)
    }

    /**
    Called when the user selects the cancel button

    - Parameter sender: The UIBarButtonItem that called the action
    */
    @IBAction func didSelectReportSaveButton(sender: UIBarButtonItem) {
//        saveData()
        self.navigationController?.popViewControllerAnimated(true)
    }


    var kPreferredTextFieldToKeyboardOffset: CGFloat = 20.0
    var keyboardFrame: CGRect = CGRect.null
    var keyboardIsShowing: Bool = false
    weak var activeTextField: UITextField?

    /// A NSDateFormatter instance for use in formatting the dateField
    var dateFormatter = NSDateFormatter()
    /// A NSNumberFormatter instance for formatting the costField
    var currencyFormatter = NSNumberFormatter()
    /// A dictionary of Reports of the form - [Report ID : Report]
    var reports: [String : Report] = [:]
    /// A string meant to temporarily hold data in case the user wants to cancel
    var tempCancelString = ""
    /// The currently selected row in the reportPicker
    var reportPickerSelectedRow = 0
    /// The current image owned by the Expense
    var currentImage: NSData!
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
                let selectedExpense = realm.objectForPrimaryKey(Expense.self, key: navC.selectedItemID)
                let containingReport = realm.objectForPrimaryKey(Report.self, key: selectedExpense!.reportID)
                if containingReport != nil {
                    reportField.text = containingReport!.name
                    if containingReport?.status != ReportStatus.Open.rawValue {
                        navigationItem.title = "View Expense"
                        costField.userInteractionEnabled = false
                        vendorField.userInteractionEnabled = false
                        dateField.userInteractionEnabled = false
                        reportField.userInteractionEnabled = false
                        detailField.userInteractionEnabled = false
                        allowImageEditing = false
                        self.navigationItem.setRightBarButtonItem(nil, animated: true)
                    }
                }
            }
        }
        else {
            self.navigationController?.navigationBar.barTintColor = .greenTintColor()
            refreshData()
            let containingReport = realm.objectForPrimaryKey(Report.self, key: selectedExpense!.reportID)
            if containingReport != nil {
                reportField.text = containingReport!.name
                if containingReport?.status != ReportStatus.Open.rawValue {
                    navigationItem.title = "View Expense"
                    costField.userInteractionEnabled = false
                    vendorField.userInteractionEnabled = false
                    dateField.userInteractionEnabled = false
                    reportField.userInteractionEnabled = false
                    detailField.userInteractionEnabled = false
                    allowImageEditing = false
                    self.navigationItem.setRightBarButtonItem(nil, animated: true)
                }
            }
        }
        
        // Set colors for items in view
        self.navigationController?.navigationBar.barTintColor = .blueTintColor()
        costField.textColor = .accentBlueColor()
    }

    override func viewWillAppear(animated: Bool) {
        shouldSave = true
    }

    /**
    Create the buttons to be shown in the Navigaton Bar
    */
    func performButtonSetup() {
        dateFormatter.dateStyle = .MediumStyle
        currencyFormatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
        currencyFormatter.locale = NSLocale(localeIdentifier: "en_US")
        let items = realm.objects(Report).filter("status==\(ReportStatus.Open.rawValue)")
        for realmReport in items {
            reports[realmReport.id] = realmReport
        }
        
        if navC == nil {
            self.navigationItem.title = "Expense"
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .Plain, target: self, action: nil)
        } else {
            self.navigationItem.title = "New Expense"
            let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(NewExpenseTableViewController.didSelectCancelButton(_:)))
            self.navigationItem.setLeftBarButtonItem(cancelButton, animated: true)
        }
        
        if navC != nil  {
            let saveButton = UIBarButtonItem(title: "Save", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(NewExpenseTableViewController.didSelectExpenseSaveButton(_:)))
            print("B")
            self.navigationItem.setRightBarButtonItem(saveButton, animated: true)
        }
    }

    /**
    Perform all necessary setup for the costField
    */
    func performCostFieldSetup() {
        let costBar: UIToolbar = UIToolbar()
        costBar.barStyle = UIBarStyle.Default
        costBar.translucent = true
        costBar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Done, target: self, action: #selector(NewExpenseTableViewController.doneBar(_:)))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Done, target: self, action: #selector(NewExpenseTableViewController.cancelBar(_:)))
        costBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        costBar.userInteractionEnabled = true
        costField.inputAccessoryView = costBar
    }

    /**
    Perform all necessary setup for the dateField
    */
    func performDateFieldSetup() {
        dateField.tintColor = .clearColor()
        dateField.text = dateFormatter.stringFromDate(NSDate())
        datePicker = UIDatePicker()
        datePicker.datePickerMode = .Date
        datePicker.addTarget(self, action: #selector(NewExpenseTableViewController.handleDatePicker(_:)), forControlEvents: UIControlEvents.ValueChanged)
        dateField.inputView = datePicker
        
        let dateBar: UIToolbar = UIToolbar()
        dateBar.barStyle = UIBarStyle.Default
        dateBar.translucent = true
        dateBar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .Done, target: self, action: #selector(NewExpenseTableViewController.doneBar(_:)))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .Done, target: self, action: #selector(NewExpenseTableViewController.cancelBar(_:)))
        dateBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        dateBar.userInteractionEnabled = true
        dateField.inputAccessoryView = dateBar
    }

    /**
    Perform all necessary setup for the reportField
    */
    func performReportFieldSetup() {
        reportField.tintColor = .clearColor()
        reportPicker = UIPickerView()
        reportPicker.delegate = self
        reportPicker.dataSource = self
        reportField.text = ""
        reportPicker.selectRow(0, inComponent: 0, animated: false)
        reportField.inputView = reportPicker
        let reportBar: UIToolbar = UIToolbar()
        reportBar.barStyle = UIBarStyle.Default
        reportBar.translucent = true
        reportBar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .Done, target: self, action: #selector(NewExpenseTableViewController.doneBar(_:)))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .Done, target: self, action: #selector(NewExpenseTableViewController.cancelBar(_:)))
        reportBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        reportBar.userInteractionEnabled = true
        reportField.inputAccessoryView = reportBar
    }

    /**
    Get the row at which a report with a given ID is at in the reportPicker
    */
    func getRow(key: String) -> Int {
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
    func handleDatePicker(sender: UIDatePicker) {
        dateField.text = dateFormatter.stringFromDate(sender.date)
    }

    /**
    Handler for the Done Button on the input accessory view of the current text field
    
    - Parameter sender: The object calling the function
    */
    func doneBar(sender: AnyObject) {
        tableView.endEditing(true)
    }

    /**
    Handler for the Cancel Button on the input accessory view of the current text field

    - Parameter sender: The object calling the function
    */
    func cancelBar(sender: UIBarButtonItem) {
        for textField in [dateField, costField, reportField] {
            if textField.isFirstResponder() {
                textField.text = tempCancelString
                textField.resignFirstResponder()
                break
            }
        }
    }

    /**
    Store the data in a textField before the user edits it, in case of cancellation

    - Parameter sender: The object calling the function
    */
    func storeCancelData(textField: UITextField) {
        tempCancelString = textField.text!
    }

    /**
    Enter any data that needs to be put into the textFields for the current expense
    */
    func refreshData() {
        if selectedExpense == nil {
            selectedExpense = realm.objectForPrimaryKey(Expense.self, key: navC.selectedItemID)
        }
        vendorField.text = selectedExpense.vendor
        costField.text = selectedExpense.cost
        dateField.text = selectedExpense.date
        detailField.text = selectedExpense.details
        datePicker.setDate(dateFormatter.dateFromString(selectedExpense.date)!, animated: false)
        reportField.text = reports[selectedExpense.reportID]?.name
        for i in 0 ..< reports.count {
            if reports[Array(reports.keys)[i]]!.id == selectedExpense.reportID {
                reportPicker.selectRow(i + 1, inComponent: 0, animated: true)
                reportField.text = reports[Array(reports.keys)[i]]!.name
                reportPickerSelectedRow = i + 1
            }
        }
        if UIImage(data: selectedExpense.imageData) != UIImage(named: "addPhoto") && NSData() != selectedExpense.imageData {
            print("Image is not default.")
            imageIsDefault = false
            expenseImage.image = UIImage(data: selectedExpense.imageData)
        }
    }

    /**
    Handler for the Done Button on the input accessory view of the current text field

    - Parameter fromCamera: Whether or not the photo will be from the camera
    */
    func getPhoto(fromCamera: Bool) {
        let imgPicker = UIImagePickerController()
        imgPicker.allowsEditing = true
        if fromCamera {
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera){
                imgPicker.sourceType = .Camera
                imgPicker.shouldAutorotate()
                imgPicker.showsCameraControls = true
            }
        } else {
            if UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary){
                imgPicker.sourceType = .PhotoLibrary
            }
        }
        imgPicker.delegate = self
        imgPicker.allowsEditing = false
        shouldSave = false;
        self.presentViewController(imgPicker, animated: true, completion: nil)
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

    //-------------------
    // MARK: - Navigation
    //-------------------
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showImageSegue" {
            let destVC = segue.destinationViewController as! ExpenseImageViewController
            destVC.image = expenseImage.image
            destVC.allowImageEditing = self.allowImageEditing
        }
    }
    
    @IBAction func doneWithImageSegue(sender: UIStoryboardSegue) {
    }
}


extension NewExpenseTableViewController: UINavigationControllerDelegate {
    
    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
//        UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: false)
    }
}


extension NewExpenseTableViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [String: AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            self.imageIsDefault = false
            
            let croppedImage = scaleAndRotateImage(pickedImage)
            
            //            let rotationCenter = CGPoint(x: croppedImage!.size.width / 2, y: croppedImage!.size.height / 2)
            
            //            var transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
            
            self.expenseImage.image = croppedImage
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func scaleAndRotateImage(image: UIImage) -> UIImage {
        let kMaxResolution: CGFloat = 640
        let imgRef: CGImageRef = image.CGImage!
        let width: CGFloat = CGFloat(CGImageGetWidth(imgRef))
        let height: CGFloat = CGFloat(CGImageGetHeight(imgRef))
        var transform: CGAffineTransform = CGAffineTransformIdentity
        var bounds: CGRect = CGRectMake(0, 0, width, height)
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
        let imageSize: CGSize = CGSizeMake(CGFloat(CGImageGetWidth(imgRef)), CGFloat(CGImageGetHeight(imgRef)))
        var boundHeight: CGFloat
        let orient: UIImageOrientation = image.imageOrientation
        switch orient {
        case UIImageOrientation.Up:
            transform = CGAffineTransformIdentity
        case UIImageOrientation.UpMirrored:
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0)
            transform = CGAffineTransformScale(transform, -1.0, 1.0)
        case UIImageOrientation.Down:
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI))
        case UIImageOrientation.DownMirrored:
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height)
            transform = CGAffineTransformScale(transform, 1.0, -1.0)
        case UIImageOrientation.LeftMirrored:
            boundHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundHeight
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width)
            transform = CGAffineTransformScale(transform, -1.0, 1.0)
            transform = CGAffineTransformRotate(transform, CGFloat(3.0 * M_PI / 2.0))
        case UIImageOrientation.Left:
            boundHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundHeight
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width)
            transform = CGAffineTransformRotate(transform, CGFloat(3.0 * M_PI / 2.0))
        case UIImageOrientation.RightMirrored:
            boundHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundHeight
            transform = CGAffineTransformMakeScale(-1.0, 1.0)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI / 2.0))
        case UIImageOrientation.Right:
            boundHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundHeight
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI / 2.0))
        }
        UIGraphicsBeginImageContext(bounds.size)
        let context: CGContextRef = UIGraphicsGetCurrentContext()!
        if orient == UIImageOrientation.Right || orient == UIImageOrientation.Left {
            CGContextScaleCTM(context, -scaleRatio, scaleRatio)
            CGContextTranslateCTM(context, -height, 0)
        }
        else {
            CGContextScaleCTM(context, scaleRatio, -scaleRatio)
            CGContextTranslateCTM(context, 0, -height)
        }
        CGContextConcatCTM(context, transform)
        CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef)
        let imageCopy: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return imageCopy
    }
}


extension NewExpenseTableViewController:  UIPickerViewDataSource, UIPickerViewDelegate {
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        reportPickerSelectedRow = row
        if row == 0 {
            reportField.text = ""
        } else {
            reportField.text = reports[Array(reports.keys)[row - 1]]?.name
        }
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return reports.count + 1
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if row == 0 {
            return "Unattached"
        }
        return reports[Array(reports.keys)[row - 1]]!.name
    }
}


extension NewExpenseTableViewController: UITextFieldDelegate {
    
    @IBAction func textFieldDidReturn(textField: UITextField!) {
        textField.resignFirstResponder()
        self.activeTextField = nil
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if (self.activeTextField != nil)
        {
            self.activeTextField?.resignFirstResponder()
            self.activeTextField = nil
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        if shouldSave {
            if selectedExpense == nil || selectedExpense.reportID == "" {
                print("Selected expense was nil")
                saveData()
            } else if let report = realm.objectForPrimaryKey(Report.self, key: selectedExpense.reportID) {
                if report.status == ReportStatus.Open.rawValue {
                    print("Selected expense was not nil")
                    saveData()
                }
            }
        }
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func performGenTextFieldSetup() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NewExpenseTableViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NewExpenseTableViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        addTargetsToTextField(vendorField)
        addTargetsToTextField(costField)
        addTargetsToTextField(dateField)
        addTargetsToTextField(reportField)
        addTargetsToTextField(detailField)
    }
    
    func addTargetsToTextField(textField: UITextField) {
        textField.addTarget(self, action: #selector(NewExpenseTableViewController.textFieldDidReturn(_:)), forControlEvents: .EditingDidEndOnExit)
        textField.addTarget(self, action: #selector(UITextFieldDelegate.textFieldDidBeginEditing(_:)), forControlEvents: .EditingDidBegin)
        textField.addTarget(self, action: #selector(NewExpenseTableViewController.storeCancelData(_:)), forControlEvents: .EditingDidBegin)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        self.keyboardIsShowing = true
        if let info = notification.userInfo {
            self.keyboardFrame = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
            self.arrangeViewOffsetFromKeyboard()
        }
        
    }
    
    func keyboardWillHide(notification: NSNotification) {
        self.keyboardIsShowing = false
        self.returnViewToInitialFrame()
    }
    
    func arrangeViewOffsetFromKeyboard() {
        let theApp: UIApplication = UIApplication.sharedApplication()
        let windowView: UIView? = theApp.delegate!.window!
        if self.activeTextField != nil {
            let textFieldLowerPoint: CGPoint = CGPointMake(self.activeTextField!.frame.origin.x, self.activeTextField!.frame.origin.y + self.activeTextField!.frame.size.height)
            
            let convertedTextFieldLowerPoint: CGPoint = self.view.convertPoint(textFieldLowerPoint, toView: windowView)
            
            let targetTextFieldLowerPoint: CGPoint = CGPointMake(self.activeTextField!.frame.origin.x, self.keyboardFrame.origin.y - kPreferredTextFieldToKeyboardOffset)
            
            let targetPointOffset: CGFloat = targetTextFieldLowerPoint.y - convertedTextFieldLowerPoint.y
            let adjustedViewFrameCenter: CGPoint = CGPointMake(self.view.center.x, self.view.center.y + targetPointOffset)
            
            if self.keyboardFrame.origin.y < (self.activeTextField!.frame.origin.y + 50) {
                UIView.animateWithDuration(0.2, animations: {
                    self.view.center = adjustedViewFrameCenter
                })
            }
        }
    }
    
    func returnViewToInitialFrame() {
        let initialViewRect: CGRect = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height)
        
        if (!CGRectEqualToRect(initialViewRect, self.view.frame))
        {
            UIView.animateWithDuration(0.2, animations: {
                self.view.frame = initialViewRect
            });
        }
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        self.activeTextField = textField
        
        if(self.keyboardIsShowing)
        {
            self.arrangeViewOffsetFromKeyboard()
        }
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        doneBar(textField)
        return false
    }
}


class SplitViewCell: UITableViewCell {
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundView = SplitLineView()
        self.backgroundColor = .whiteColor()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.backgroundView = SplitLineView()
        self.backgroundColor = .whiteColor()
    }
}

class BottomLineCell: UITableViewCell {
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundView = BottomLineView()
        self.backgroundColor = .whiteColor()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.backgroundView = BottomLineView()
        self.backgroundColor = .whiteColor()
    }
}

class SplitLineView: UIView {
    
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0)
        CGContextFillRect(context, CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height))
        CGContextSetRGBFillColor(context, 0.85, 0.85, 0.85, 1.0)
        CGContextFillRect(context, CGRect(x: bounds.width / 2, y: 0, width: 0.8, height: bounds.height))
    }
}

class BottomLineView: UIView {
    
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0)
        CGContextFillRect(context, CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height))
        CGContextSetRGBFillColor(context, 0.85, 0.85, 0.85, 1.85)
        CGContextFillRect(context, CGRect(x: 0, y: bounds.height - 1, width: bounds.width, height: 1))
    }
}

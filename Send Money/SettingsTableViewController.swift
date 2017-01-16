//
//  SettingsTableViewController.swift
//  Send Money
//
//  Created by Eric Marshall on 8/1/15.
//  Copyright (c) 2015 Eric Marshall. All rights reserved.
//

import UIKit
import RealmSwift
import MessageUI

class SettingsTableViewController: UITableViewController {

    //---------------------------------------------------
    // MARK: - Tutorial showing/hiding on launch controls
    //---------------------------------------------------
    @IBOutlet weak var showTutorialAtLaunchSwitch: UISwitch!

    @IBAction func showTutorialAtLaunchSwitchDidChange(sender: UISwitch) {
        try! realm.write {
            self.settings.showTutorial = sender.on
        }
    }

    //-----------------------------------------------
    // MARK: - Versioning Label and App Store reviews
    //-----------------------------------------------
    @IBAction func didSelectReviewCell(sender: UITapGestureRecognizer) {

        let path: NSURL = NSURL(string: "itms-apps://itunes.apple.com/us/app/id1028920691")!

        UIApplication.sharedApplication().openURL(path)
    }

    @IBOutlet weak var currentVersionLabel: UILabel!

    //-------------------------------------------
    // MARK: - Displaying information to the user
    //-------------------------------------------

    let realm = try! Realm()
    let numberFormatter = NSNumberFormatter()
    var settings: Settings!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.barTintColor = .redTintColor()
        settings = realm.objects(Settings)[0] as Settings
        updateDeleteDelayDetail()
        
        currentVersionLabel.text = ""
        if let version = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String {
            if let build = NSBundle.mainBundle().infoDictionary?["CFBundleVersion"] as? String {
                currentVersionLabel.text = "Version \(version) (\(build))"
            }
        }
        
        numberFormatter.numberStyle = .CurrencyStyle
    }
    
    override func viewWillAppear(animated: Bool) {
        updateDeleteDelayDetail()
        self.navigationController?.toolbarHidden = true
        for section in 0 ..< tableView.numberOfSections {
            for i in 0 ..< tableView.numberOfRowsInSection(section) {
                if tableView.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: section))!.selected {
                   tableView.deselectRowAtIndexPath(NSIndexPath(forRow: i, inSection: section), animated: false)
                }
            }
        }
        showTutorialAtLaunchSwitch.on = settings.showTutorial
    }
    
    override func viewDidLayoutSubviews() {
        updateDeleteDelayDetail()
    }
    
    func updateDeleteDelayDetail() {
        var delay: String!
        switch settings.deleteIntervalRow {
        case 0:
            delay = "1 Day"
        case 1:
            delay = "3 Days"
        case 2:
            delay = "7 Days"
        case 3:
            delay = "14 Days"
        case 4:
            delay = "30 Days"
        case 5:
            delay = "90 Days"
        default:
            delay = "Never"
        }
        tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0))?.detailTextLabel?.text = delay
        
        switch settings.emailList.count {
            case 1:
                tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0))?.detailTextLabel?.text = "\(settings.emailList.count) Recipient"
            default:
                tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0))?.detailTextLabel?.text = "\(settings.emailList.count) Recipients"
        }

    }

    
    //-------------------
    // MARK: - Navigation
    //-------------------

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDeleteDelaySegue" {
            let destVC = segue.destinationViewController as! DeleteDelayTableViewController
            destVC.hidesBottomBarWhenPushed = true
        }
        if segue.identifier == "showEmailListSegue" {
            let destVC = segue.destinationViewController as! EmailListTableViewController
            destVC.hidesBottomBarWhenPushed = true
        }
        if segue.identifier == "showTutorialSegue" {
            let destVC = segue.destinationViewController as! TutorialViewController
            destVC.hidesBottomBarWhenPushed = true
            destVC.title = "Tutorial"
            destVC.shownAtBeginning = false
        }
        
    }
}
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

    @IBAction func showTutorialAtLaunchSwitchDidChange(_ sender: UISwitch) {
        try! realm.write {
            self.settings.showTutorial = sender.isOn
        }
    }

    //-----------------------------------------------
    // MARK: - Versioning Label and App Store reviews
    //-----------------------------------------------
    @IBAction func didSelectReviewCell(_ sender: UITapGestureRecognizer) {

        let path: URL = URL(string: "itms-apps://itunes.apple.com/us/app/id1028920691")!

        UIApplication.shared.openURL(path)
    }

    @IBOutlet weak var currentVersionLabel: UILabel!

    //-------------------------------------------
    // MARK: - Displaying information to the user
    //-------------------------------------------

    let realm = try! Realm()
    let numberFormatter = NumberFormatter()
    var settings: Settings!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.barTintColor = .redTintColor()
        settings = realm.objects(Settings.self)[0] as Settings
        updateDeleteDelayDetail()
        
        currentVersionLabel.text = ""
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                currentVersionLabel.text = "Version \(version) (\(build))"
            }
        }
        
        numberFormatter.numberStyle = .currency
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updateDeleteDelayDetail()
        self.navigationController?.isToolbarHidden = true
        for section in 0 ..< tableView.numberOfSections {
            for i in 0 ..< tableView.numberOfRows(inSection: section) {
                if tableView.cellForRow(at: IndexPath(row: i, section: section))!.isSelected {
                   tableView.deselectRow(at: IndexPath(row: i, section: section), animated: false)
                }
            }
        }
        showTutorialAtLaunchSwitch.isOn = settings.showTutorial
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
        tableView.cellForRow(at: IndexPath(row: 1, section: 0))?.detailTextLabel?.text = delay
        
        switch settings.emailList.count {
            case 1:
                tableView.cellForRow(at: IndexPath(row: 0, section: 0))?.detailTextLabel?.text = "\(settings.emailList.count) Recipient"
            default:
                tableView.cellForRow(at: IndexPath(row: 0, section: 0))?.detailTextLabel?.text = "\(settings.emailList.count) Recipients"
        }

    }

    
    //-------------------
    // MARK: - Navigation
    //-------------------

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDeleteDelaySegue" {
            let destVC = segue.destination as! DeleteDelayTableViewController
            destVC.hidesBottomBarWhenPushed = true
        }
        if segue.identifier == "showEmailListSegue" {
            let destVC = segue.destination as! EmailListTableViewController
            destVC.hidesBottomBarWhenPushed = true
        }
        if segue.identifier == "showTutorialSegue" {
            let destVC = segue.destination as! TutorialViewController
            destVC.hidesBottomBarWhenPushed = true
            destVC.title = "Tutorial"
            destVC.shownAtBeginning = false
        }
        
    }
}

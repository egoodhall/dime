//
//  DeleteDelayTableViewController.swift
//  Send Money
//
//  Created by Eric Marshall on 8/2/15.
//  Copyright (c) 2015 Eric Marshall. All rights reserved.
//

import UIKit
import RealmSwift

class DeleteDelayTableViewController: UITableViewController {

    let realm = try! Realm()
    var settings: Settings!
    
    override func viewDidLoad() {
        settings = realm.objects(Settings)[0] as Settings
        for i in 0 ..< tableView.numberOfRowsInSection(0) {
            self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: 0))!.accessoryType = .None
        }
        updateSelectedRow(settings.deleteIntervalRow)
    }
    
    func updateSelectedRow(row: Int) {
        for i in 0 ..< tableView.numberOfRowsInSection(0) {
            self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: 0))!.accessoryType = .None
        }
        self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: settings.deleteIntervalRow, inSection: 0))?.accessoryType = .None
        try! realm.write {
            self.settings.deleteIntervalRow = row
        }
        self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: settings.deleteIntervalRow, inSection: 0))?.accessoryType = .Checkmark
    }
    
    //-------------------------------
    // MARK: - Table view data source
    //-------------------------------

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        updateSelectedRow(indexPath.row)
    }
}

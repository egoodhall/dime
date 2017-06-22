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
        settings = realm.objects(Settings.self)[0] as Settings
        for i in 0 ..< tableView.numberOfRows(inSection: 0) {
            self.tableView.cellForRow(at: IndexPath(row: i, section: 0))!.accessoryType = .none
        }
        updateSelectedRow(settings.deleteIntervalRow)
    }
    
    func updateSelectedRow(_ row: Int) {
        for i in 0 ..< tableView.numberOfRows(inSection: 0) {
            self.tableView.cellForRow(at: IndexPath(row: i, section: 0))!.accessoryType = .none
        }
        self.tableView.cellForRow(at: IndexPath(row: settings.deleteIntervalRow, section: 0))?.accessoryType = .none
        try! realm.write {
            self.settings.deleteIntervalRow = row
        }
        self.tableView.cellForRow(at: IndexPath(row: settings.deleteIntervalRow, section: 0))?.accessoryType = .checkmark
    }
    
    //-------------------------------
    // MARK: - Table view data source
    //-------------------------------

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        updateSelectedRow(indexPath.row)
    }
}

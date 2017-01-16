//
//  CustomTableViewCell.swift
//  Send Money
//
//  Created by Eric Marshall on 7/22/15.
//  Copyright (c) 2015 Eric Marshall. All rights reserved.
//

import UIKit

class CustomExpenseViewCell: UITableViewCell {

    /// Label for showing the Expense's Vendor
    @IBOutlet weak var vendorLabel: UILabel!
    /// Label for showing the Expense's Date
    @IBOutlet weak var dateLabel: UILabel!
    /// Label for showing the Report the Expense is contained in
    @IBOutlet weak var reportLabel: UILabel!
    /// Label for showing the Expense's Cost
    @IBOutlet weak var costLabel: UILabel!
    /// The UIImageView for displaying the Expense's attached image
    @IBOutlet weak var expenseImage: UIImageView!
}
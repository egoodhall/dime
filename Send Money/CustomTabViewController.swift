//
//  CustomTabViewController.swift
//  Send Money
//
//  Created by Eric Marshall on 7/26/15.
//  Copyright (c) 2015 Eric Marshall. All rights reserved.
//

import UIKit

class CustomTabViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        var myBarItems = self.tabBar.items as [UITabBarItem]!
        myBarItems?[0].selectedImage = UIImage(named: "SelectedExpenseIcon.pdf")

        myBarItems?[1].selectedImage = UIImage(named: "SelectedReportIcon.pdf")

        myBarItems?[2].selectedImage = UIImage(named: "SelectedGearIcon.pdf")
    }
}

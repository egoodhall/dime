//
//  IntermediateNavigationController.swift
//  Send Money
//
//  Created by Eric Marshall on 7/22/15.
//  Copyright (c) 2015 Eric Marshall. All rights reserved.
//

import UIKit

class IntermediateNavigationController: UINavigationController {

    var selectedItemID: String!
    var sender: editSender = .expenseTable
}

enum editSender {
    case reportTable
    case expenseTable
    case none
}

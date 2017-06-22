//
//  AnimatedTutorial.swift
//  Send Money
//
//  Created by Eric Marshall on 7/14/16.
//  Copyright © 2016 Eric Marshall. All rights reserved.
//

import Foundation
import UIKit
import RazzleDazzle

class AnimatedTutorial: AnimatedPagingScrollViewController {

    var firstLabel = UILabel()

    override func numberOfPages() -> Int {
        return 5
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.addSubview(firstLabel)
        contentView.addConstraint(NSLayoutConstraint(item: firstLabel, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1, constant: 0))
        keepView(firstLabel, onPages: [1,2])
        keepView(firstLabel, onPage: 1.25)
    }
}

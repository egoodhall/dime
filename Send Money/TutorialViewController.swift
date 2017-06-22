//
//  AnimatedTutorial.swift
//  Send Money
//
//  Created by Eric Marshall on 7/14/16.
//  Copyright © 2016 Eric Marshall. All rights reserved.
//

import Foundation
import RealmSwift
import UIKit
import RazzleDazzle
import SSBouncyButton
import OnOffButton

class TutorialViewController: AnimatedPagingScrollViewController {

    var realm: Realm!
    var shownAtBeginning = true
    var settings: Settings!
    
    fileprivate let pageControl = UIPageControl()

    fileprivate let prompt1 = "Dime makes expense reports quick and painless"
    fileprivate let prompt2 = "Expenses hold information about transactions"
    fileprivate let prompt3 = "Reports let you group Expenses together"
    fileprivate let prompt4 = "Compile Reports into PDFs and send directly from your email"

    // First Page
    fileprivate let envelopeFront = UIImageView(image: UIImage(named: "Envelope-Front"))
    fileprivate let envelopeBack = UIImageView(image: UIImage(named: "Envelope-Back"))
    fileprivate let paper = UIImageView(image: UIImage(named: "Paper"))
    fileprivate let dollar = UIImageView(image: UIImage(named: "Dollar"))
    fileprivate let prompt1Label = UILabel()

    // Second Page
    fileprivate let prompt2Label = UILabel()
    fileprivate let expense1 = UIImageView(image: UIImage(named: "Expense"))
    fileprivate let burger = UIImageView(image: UIImage(named: "Burger"))
    fileprivate let fries = UIImageView(image: UIImage(named: "Fries"))

    // Third Page
    fileprivate let prompt3Label = UILabel()
    fileprivate let expense2 = UIImageView(image: UIImage(named: "Expense"))

    // Fourth Page
    fileprivate let prompt4Label = UILabel()
    fileprivate let letsGoBtn = SSBouncyButton()
    fileprivate let showAgainBtn = OnOffButton()
    fileprivate let showAgainView = UIView()
    fileprivate let showAgainText = UILabel()

    override func numberOfPages() -> Int {
        return 4
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        realm = try! Realm()
        settings = realm.objects(Settings.self)[0] as Settings

        setupPageControl()
        doFirstPageSetup()
        doSecondPageSetup()
        doThirdPageSetup()
        doFourthPageSetup()

        setBackground()
    }
    
    func setupPageControl() {
        contentView.addSubview(pageControl)
        
        pageControl.numberOfPages = numberOfPages()
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = UIColor(r: 200, g: 200, b: 200, alpha: 0.5)
        pageControl.currentPageIndicatorTintColor = UIColor(r: 200, g: 200, b: 200, alpha: 1.0)
        
        let bottomY = NSLayoutConstraint(item: pageControl, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1.0, constant: 0)
        
        contentView.addConstraints([bottomY])
        
        let update = PageControlUpdater(pageControl: pageControl)
        update[0] = 0
        update[1] = 1
        update[2] = 2
        update[3] = 3
        animator.addAnimation(update)
        
        keepView(pageControl, onPages: [-1,0,1,2,3,4])
    }

    //===================
    // Mark: - First Page
    //===================

    func doFirstPageSetup() {
        setupEnvelopeBack()
        setupPaper()
        setupDollar()
        setupEnvelopeFront()
        setupPrompt1()
    }

    func setupPrompt1() {
        contentView.addSubview(prompt1Label)

        prompt1Label.text = prompt1
        prompt1Label.numberOfLines = 0
        prompt1Label.textAlignment = .center
        prompt1Label.textColor = UIColor.white
        prompt1Label.font = UIFont(name: "PT Sans", size: 24)

        let topY = NSLayoutConstraint(item: prompt1Label, attribute: .top, relatedBy: .equal, toItem: envelopeBack, attribute: .bottom, multiplier: 1.1, constant: 0)
        let width = NSLayoutConstraint(item: prompt1Label, attribute: .width, relatedBy: .equal, toItem: .none, attribute: .notAnAttribute, multiplier: 1, constant: view.bounds.width - 100)
        contentView.addConstraints([topY, width])

        let slide = ConstraintConstantAnimation(superview: scrollView, constraint: topY)
        slide[0] = 0
        slide[0.5] = -48

        animator.addAnimation(slide)

        keepView(prompt1Label, onPages: [-1, 0,1])
    }

    func setupEnvelopeBack() {
        // Add the envelope's back to view
        contentView.addSubview(envelopeBack)


        // Set the widths
        let width = NSLayoutConstraint(item: envelopeBack, attribute: .width, relatedBy: .equal, toItem: .none, attribute: .notAnAttribute, multiplier: 1, constant: view.bounds.width - 200.0)
        let height = NSLayoutConstraint(item: envelopeBack, attribute: .height, relatedBy: .equal, toItem: envelopeBack, attribute: .width, multiplier: 0.916, constant: 0)
        let centerY = NSLayoutConstraint(item: envelopeBack, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 0.75, constant: 0)
        contentView.addConstraints([width, height, centerY])


        // Set the animations
        let slide = ConstraintConstantAnimation(superview: scrollView, constraint: centerY)
        slide[-1] = -100
        slide[0] = 0
        slide[0.5] = view.bounds.height * 0.625 + (envelopeBack.bounds.height / 2)
        slide[2] = view.bounds.height * 0.625 + (envelopeBack.bounds.height / 2)
        slide[3] = 0
        slide[4] = -100
        animator.addAnimation(slide)


        keepView(envelopeBack, onPages: [-1, 0,1, 3, 4])
    }

    func setupEnvelopeFront() {
        // Add the envelope's front to the view
        contentView.addSubview(envelopeFront)

        // Add the
        let width = NSLayoutConstraint(item: envelopeFront, attribute: .width, relatedBy: .equal, toItem: envelopeBack, attribute: .width, multiplier: 1, constant: 0)
        let height = NSLayoutConstraint(item: envelopeFront, attribute: .height, relatedBy: .equal, toItem: envelopeBack, attribute: .height, multiplier: 1, constant: 0)
        let centerY = NSLayoutConstraint(item: envelopeFront, attribute: .centerY, relatedBy: .equal, toItem: envelopeBack, attribute: .centerY, multiplier: 1, constant: 0)
        contentView.addConstraints([width, height, centerY])

        keepView(envelopeFront, onPages: [-1, 0, 1, 3, 4])
    }

    func setupPaper() {
        contentView.addSubview(paper)

        let height = NSLayoutConstraint(item: paper, attribute: .height, relatedBy: .equal, toItem: envelopeBack, attribute: .height, multiplier: 0.8, constant: 0)
        contentView.addConstraint(height)
        let width = NSLayoutConstraint(item: paper, attribute: .width, relatedBy: .equal, toItem: paper, attribute: .height, multiplier: 0.77381, constant: 0)
        contentView.addConstraint(width)
        let centerY = NSLayoutConstraint(item: paper, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 0.75, constant: 0)
        contentView.addConstraints([width, height, centerY])

        let scale = ScaleAnimation(view: paper)
        scale[0] = 1
        scale[0.2] = 1
        scale[1] = 2.5
        scale[2] = 2
        scale[3] = 1
        animator.addAnimation(scale)

        let slide = ConstraintConstantAnimation(superview: scrollView, constraint: centerY)
        slide[-1] = -200
        slide[0] = 0
        slide[1] = 275
        slide[2] = 150
        slide[3] = 0
        slide[4] = -200
        animator.addAnimation(slide)

        let fade = AlphaAnimation(view: paper)
        fade[0] = 1
        fade[0.5] = 0
        fade[1] = 0
        fade[2] = 0
        fade[3] = 1
        animator.addAnimation(fade)

        keepView(paper, onPages: [-1, 0, 1, 2, 3, 4])
    }

    func setupDollar() {
        contentView.addSubview(dollar)

        let height = NSLayoutConstraint(item: dollar, attribute: .height, relatedBy: .equal, toItem: paper, attribute: .height, multiplier: 1, constant: 0)
        contentView.addConstraint(height)
        let width = NSLayoutConstraint(item: dollar, attribute: .width, relatedBy: .equal, toItem: paper, attribute: .width, multiplier: 1, constant: 0)
        contentView.addConstraint(width)
        let centerY = NSLayoutConstraint(item: dollar, attribute: .centerY, relatedBy: .equal, toItem: paper, attribute: .centerY, multiplier: 1.0, constant: 0)
        contentView.addConstraints([width, height, centerY])

        let scale = ScaleAnimation(view: dollar)
        scale[0] = 1
        scale[0.2] = 1
        scale[1] = 2.5
        scale[2] = 2
        scale[3] = 1
        animator.addAnimation(scale)

        let fade = AlphaAnimation(view: dollar)
        fade[0] = 1
        fade[0.5] = 0
        fade[1] = 0
        fade[2] = 0
        fade[3] = 1
        animator.addAnimation(fade)

        keepView(dollar, onPages: [-1, 0, 1, 2, 3, 4])
    }

    func setBackground() {
        let bgdAnimation = BackgroundColorAnimation(view: view)
        bgdAnimation[0] = UIColor.blueTintColor()
        animator.addAnimation(bgdAnimation)
    }

    //====================
    // Mark: - Second Page
    //====================

    func doSecondPageSetup() {
        setupPrompt2()
        setupExpense1()
        setupBurgerAndFries()
    }

    func setupPrompt2() {
        contentView.addSubview(prompt2Label)

        prompt2Label.text = prompt2
        prompt2Label.numberOfLines = 0
        prompt2Label.textAlignment = .center
        prompt2Label.textColor = UIColor.white
        prompt2Label.font = UIFont(name: "PT Sans", size: 24)

        let topY = NSLayoutConstraint(item: prompt2Label, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1, constant: -90)
        let width = NSLayoutConstraint(item: prompt2Label, attribute: .width, relatedBy: .equal, toItem: .none, attribute: .notAnAttribute, multiplier: 1, constant: view.bounds.width - 100)
        contentView.addConstraints([topY, width])

        let slide = ConstraintConstantAnimation(superview: contentView, constraint: topY)
        slide[0] = -90
        slide[1] = 90
        animator.addAnimation(slide)

        keepView(prompt2Label, onPages: [0,1])
    }

    func setupExpense1() {
        contentView.addSubview(expense1)

        let height = NSLayoutConstraint(item: expense1, attribute: .height, relatedBy: .equal, toItem: envelopeBack, attribute: .height, multiplier: 0.8, constant: 0)
        contentView.addConstraint(height)
        let width = NSLayoutConstraint(item: expense1, attribute: .width, relatedBy: .equal, toItem: paper, attribute: .height, multiplier: 0.77381, constant: 0)
        contentView.addConstraint(width)
        let centerY = NSLayoutConstraint(item: expense1, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 0.75, constant: 0)
        contentView.addConstraints([width, height, centerY])
        contentView.sendSubview(toBack: expense1)

        let scale = ScaleAnimation(view: expense1)
        scale[0] = 1
        scale[0.2] = 1
        scale[1] = 2.5
        scale[2] = 2
        scale[3] = 1
        animator.addAnimation(scale)

        let slide = ConstraintConstantAnimation(superview: scrollView, constraint: centerY)
        slide[-1] = -200
        slide[0] = 0
        slide[1] = 275
        slide[2] = 150
        slide[3] = 0
        slide[4] = -200
        animator.addAnimation(slide)

        let rotate = RotationAnimation(view: expense1)
        rotate[1] = 0
        rotate[2] = -10
        rotate[3] = 0
        animator.addAnimation(rotate)

        keepView(expense1, onPages: [-1, 0, 1, 2.1, 3, 4], atTimes: [-1, 0, 1, 2, 3, 4])
    }

    func setupBurgerAndFries() {
        contentView.addSubview(fries)

        let topY = NSLayoutConstraint(item: fries, attribute: .top, relatedBy: .equal, toItem: prompt2Label, attribute: .bottom, multiplier: 1, constant: 40)
        let friesHeight = NSLayoutConstraint(item: fries, attribute: .height, relatedBy: .equal, toItem: .none, attribute: .notAnAttribute, multiplier: 1, constant: 120)
        let friesWidth = NSLayoutConstraint(item: fries, attribute: .width, relatedBy: .equal, toItem: fries, attribute: .height, multiplier: 0.65182, constant: 0)
        contentView.addConstraints([topY, friesHeight, friesWidth])

        let slide = ConstraintConstantAnimation(superview: contentView, constraint: topY)
        slide[0] = 130
        slide[1] = 40
        animator.addAnimation(slide)

        keepView(fries, onPages: [1.07])

        contentView.addSubview(burger)

        let bottomY = NSLayoutConstraint(item: burger, attribute: .bottom, relatedBy: .equal, toItem: fries, attribute: .bottom, multiplier: 1, constant: 0)
        let burgerWidth = NSLayoutConstraint(item: burger, attribute: .width, relatedBy: .equal, toItem: fries, attribute: .width, multiplier: 1.47826, constant: 0)
        let burgerHeight = NSLayoutConstraint(item: burger, attribute: .height, relatedBy: .equal, toItem: burger, attribute: .width, multiplier: 0.76891, constant: 0)
        contentView.addConstraints([bottomY, burgerHeight, burgerWidth])

        keepView(burger, onPages: [0.93])
    }

    //===================
    // Mark: - Third Page
    //===================

    func doThirdPageSetup() {
        setupPrompt3()
        setupExpense2()
    }

    func setupPrompt3() {
        contentView.addSubview(prompt3Label)

        prompt3Label.text = prompt3
        prompt3Label.numberOfLines = 0
        prompt3Label.textAlignment = .center
        prompt3Label.textColor = UIColor.white
        prompt3Label.font = UIFont(name: "PT Sans", size: 24)

        let topY = NSLayoutConstraint(item: prompt3Label, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1, constant: -90)
        let width = NSLayoutConstraint(item: prompt3Label, attribute: .width, relatedBy: .equal, toItem: .none, attribute: .notAnAttribute, multiplier: 1, constant: view.bounds.width - 100)
        contentView.addConstraints([topY, width])

        let slide = ConstraintConstantAnimation(superview: contentView, constraint: topY)
        slide[1] = -90
        slide[2] = 90
        animator.addAnimation(slide)

        keepView(prompt3Label, onPages: [1, 2])
    }

    func setupExpense2() {
        contentView.addSubview(expense2)

        let height = NSLayoutConstraint(item: expense2, attribute: .height, relatedBy: .equal, toItem: envelopeBack, attribute: .height, multiplier: 0.8, constant: 0)
        let width = NSLayoutConstraint(item: expense2, attribute: .width, relatedBy: .equal, toItem: paper, attribute: .height, multiplier: 0.77381, constant: 0)
        let centerY = NSLayoutConstraint(item: expense2, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 0.75, constant: 0)
        contentView.addConstraints([width, height, centerY])
        contentView.sendSubview(toBack: expense2)

        let scale = ScaleAnimation(view: expense2)
        scale[0] = 1
        scale[0.2] = 1
        scale[1] = 2.5
        scale[2] = 2
        scale[3] = 1
        animator.addAnimation(scale)

        let slide = ConstraintConstantAnimation(superview: scrollView, constraint: centerY)
        slide[-1] = -200
        slide[0] = 0
        slide[1] = 275
        slide[2] = 150
        slide[3] = 0
        slide[4] = -200
        animator.addAnimation(slide)

        let rotate = RotationAnimation(view: expense2)
        rotate[1] = 0
        rotate[2] = 10
        rotate[3] = 0
        animator.addAnimation(rotate)

        keepView(expense2, onPages: [-1, 0, 1, 1.9, 3, 4], atTimes: [-1, 0, 1, 2, 3, 4])
    }

    //====================
    // Mark: - Fourth Page
    //====================

    func doFourthPageSetup() {
        setupPrompt4()
        setupLetsGoBtn()
        setupShowAgainBtn()
        if (!shownAtBeginning) {
            letsGoBtn.isEnabled = false
            showAgainBtn.isEnabled = false
        }
        setupShowAgainPrompt()
    }

    func setupPrompt4() {
        contentView.addSubview(prompt4Label)

        prompt4Label.text = prompt4
        prompt4Label.numberOfLines = 0
        prompt4Label.textAlignment = .center
        prompt4Label.textColor = UIColor.white
        prompt4Label.font = UIFont(name: "PT Sans", size: 24)

        let topY = NSLayoutConstraint(item: prompt4Label, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1, constant: -90)
        let width = NSLayoutConstraint(item: prompt4Label, attribute: .width, relatedBy: .equal, toItem: .none, attribute: .notAnAttribute, multiplier: 1, constant: view.bounds.width - 100)
        contentView.addConstraints([topY, width])

        let slide = ConstraintConstantAnimation(superview: contentView, constraint: topY)
        slide[2] = -90
        slide[3] = 70
        animator.addAnimation(slide)

        animator.addAnimation(slide)

        keepView(prompt4Label, onPages: [2, 3, 4])
    }

    func setupShowAgainPrompt() {
        contentView.addSubview(showAgainText)

        showAgainText.text = "Always show tutorial"
        showAgainText.textAlignment = .left
        showAgainText.textColor = .lightGray
        showAgainText.font = UIFont(name: "PT Sans", size: 20)

        let centerY = NSLayoutConstraint(item: showAgainText, attribute: .centerY, relatedBy: .equal, toItem: showAgainBtn, attribute: .centerY, multiplier: 1, constant: 0)
        contentView.addConstraints([centerY])

        keepView(showAgainText, onPages: [2, 3.05], atTimes: [2, 3])
    }

    func setupShowAgainBtn() {
        contentView.addSubview(showAgainBtn)
        showAgainBtn.lineWidth = 1.5
        showAgainBtn.ringAlpha = 0.2
        showAgainBtn.strokeColor = .green
        showAgainBtn.addTarget(self, action: #selector(TutorialViewController.didTapOnOffButton), for: .touchUpInside)

        let topY = NSLayoutConstraint(item: showAgainBtn, attribute: .top, relatedBy: .equal, toItem: letsGoBtn, attribute: .bottom, multiplier: 1, constant: 8)
        let width = NSLayoutConstraint(item: showAgainBtn, attribute: .width, relatedBy: .equal, toItem: .none, attribute: .notAnAttribute, multiplier: 1, constant: 42)
        let height = NSLayoutConstraint(item: showAgainBtn, attribute: .height, relatedBy: .equal, toItem: showAgainBtn, attribute: .height, multiplier: 1, constant: 0)

        contentView.addConstraints([topY, width, height])

        keepView(showAgainBtn, onPages: [2, 2.75], atTimes: [2, 3])
    }

    func didTapOnOffButton() {
        showAgainBtn.checked = !showAgainBtn.checked
        if (showAgainBtn.checked) {
            showAgainBtn.strokeColor = .green
        } else {
            showAgainBtn.strokeColor = .lightGray
        }
    }

    func setupLetsGoBtn() {
        contentView.addSubview(letsGoBtn)
        letsGoBtn.setTitle("Let's Go!", for: UIControlState())
        letsGoBtn.setTitle("Let's Go!", for: .selected)
        letsGoBtn.titleLabel?.font = UIFont(name: "PT Sans", size: 30)
        letsGoBtn.tintColor = UIColor(r: 255, g: 255, b: 255, alpha: 0.4)
        letsGoBtn.cornerRadius = 39
        letsGoBtn.isSelected = true

        let topY = NSLayoutConstraint(item: letsGoBtn, attribute: .top, relatedBy: .equal, toItem: envelopeBack, attribute: .bottom, multiplier: 1, constant: 48)
        let width = NSLayoutConstraint(item: letsGoBtn, attribute: .width, relatedBy: .equal, toItem: .none, attribute: .notAnAttribute, multiplier: 1, constant: 200)
        let height = NSLayoutConstraint(item: letsGoBtn, attribute: .height, relatedBy: .equal, toItem: .none, attribute: .notAnAttribute, multiplier: 1, constant: 80)

        letsGoBtn.addTarget(self, action: #selector(TutorialViewController.didTapLetsGoBtn), for: .touchUpInside)

        contentView.addConstraints([topY, width, height])

        keepView(letsGoBtn, onPages: [2,3])
    }

    func didTapLetsGoBtn() {
        try! realm.write({
            settings.showTutorial = showAgainBtn.checked
        })
        let nextVC = storyboard?.instantiateViewController(withIdentifier: "mainAppRootTabController") as! CustomTabViewController
        self.present(nextVC, animated: true, completion: nil)
    }
}

open class PageControlUpdater: Animation<CGFloat>, Animatable {
    
    fileprivate let pageControl : UIPageControl
    
    public init(pageControl: UIPageControl) {
        self.pageControl = pageControl
    }
    
    open override func validateValue(_ value: CGFloat) -> Bool {
        return (value >= 0) && (Int(value) <= pageControl.numberOfPages)
    }
    
    open func animate(_ time: CGFloat) {
        if !hasKeyframes() {return}
        pageControl.currentPage = Int(time)
        pageControl.updateCurrentPageDisplay()
    }
}












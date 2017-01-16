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
    
    private let pageControl = UIPageControl()

    private let prompt1 = "Dime makes expense reports quick and painless"
    private let prompt2 = "Expenses hold information about transactions"
    private let prompt3 = "Reports let you group Expenses together"
    private let prompt4 = "Compile Reports into PDFs and send directly from your email"

    // First Page
    private let envelopeFront = UIImageView(image: UIImage(named: "Envelope-Front"))
    private let envelopeBack = UIImageView(image: UIImage(named: "Envelope-Back"))
    private let paper = UIImageView(image: UIImage(named: "Paper"))
    private let dollar = UIImageView(image: UIImage(named: "Dollar"))
    private let prompt1Label = UILabel()

    // Second Page
    private let prompt2Label = UILabel()
    private let expense1 = UIImageView(image: UIImage(named: "Expense"))
    private let burger = UIImageView(image: UIImage(named: "Burger"))
    private let fries = UIImageView(image: UIImage(named: "Fries"))

    // Third Page
    private let prompt3Label = UILabel()
    private let expense2 = UIImageView(image: UIImage(named: "Expense"))

    // Fourth Page
    private let prompt4Label = UILabel()
    private let letsGoBtn = SSBouncyButton()
    private let showAgainBtn = OnOffButton()
    private let showAgainView = UIView()
    private let showAgainText = UILabel()

    override func numberOfPages() -> Int {
        return 4
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        realm = try! Realm()
        settings = realm.objects(Settings)[0] as Settings

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
        
        let bottomY = NSLayoutConstraint(item: pageControl, attribute: .Bottom, relatedBy: .Equal, toItem: contentView, attribute: .Bottom, multiplier: 1.0, constant: 0)
        
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
        prompt1Label.textAlignment = .Center
        prompt1Label.textColor = UIColor.whiteColor()
        prompt1Label.font = UIFont(name: "PT Sans", size: 24)

        let topY = NSLayoutConstraint(item: prompt1Label, attribute: .Top, relatedBy: .Equal, toItem: envelopeBack, attribute: .Bottom, multiplier: 1.1, constant: 0)
        let width = NSLayoutConstraint(item: prompt1Label, attribute: .Width, relatedBy: .Equal, toItem: .None, attribute: .NotAnAttribute, multiplier: 1, constant: view.bounds.width - 100)
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
        let width = NSLayoutConstraint(item: envelopeBack, attribute: .Width, relatedBy: .Equal, toItem: .None, attribute: .NotAnAttribute, multiplier: 1, constant: view.bounds.width - 200.0)
        let height = NSLayoutConstraint(item: envelopeBack, attribute: .Height, relatedBy: .Equal, toItem: envelopeBack, attribute: .Width, multiplier: 0.916, constant: 0)
        let centerY = NSLayoutConstraint(item: envelopeBack, attribute: .CenterY, relatedBy: .Equal, toItem: contentView, attribute: .CenterY, multiplier: 0.75, constant: 0)
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
        let width = NSLayoutConstraint(item: envelopeFront, attribute: .Width, relatedBy: .Equal, toItem: envelopeBack, attribute: .Width, multiplier: 1, constant: 0)
        let height = NSLayoutConstraint(item: envelopeFront, attribute: .Height, relatedBy: .Equal, toItem: envelopeBack, attribute: .Height, multiplier: 1, constant: 0)
        let centerY = NSLayoutConstraint(item: envelopeFront, attribute: .CenterY, relatedBy: .Equal, toItem: envelopeBack, attribute: .CenterY, multiplier: 1, constant: 0)
        contentView.addConstraints([width, height, centerY])

        keepView(envelopeFront, onPages: [-1, 0, 1, 3, 4])
    }

    func setupPaper() {
        contentView.addSubview(paper)

        let height = NSLayoutConstraint(item: paper, attribute: .Height, relatedBy: .Equal, toItem: envelopeBack, attribute: .Height, multiplier: 0.8, constant: 0)
        contentView.addConstraint(height)
        let width = NSLayoutConstraint(item: paper, attribute: .Width, relatedBy: .Equal, toItem: paper, attribute: .Height, multiplier: 0.77381, constant: 0)
        contentView.addConstraint(width)
        let centerY = NSLayoutConstraint(item: paper, attribute: .CenterY, relatedBy: .Equal, toItem: contentView, attribute: .CenterY, multiplier: 0.75, constant: 0)
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

        let height = NSLayoutConstraint(item: dollar, attribute: .Height, relatedBy: .Equal, toItem: paper, attribute: .Height, multiplier: 1, constant: 0)
        contentView.addConstraint(height)
        let width = NSLayoutConstraint(item: dollar, attribute: .Width, relatedBy: .Equal, toItem: paper, attribute: .Width, multiplier: 1, constant: 0)
        contentView.addConstraint(width)
        let centerY = NSLayoutConstraint(item: dollar, attribute: .CenterY, relatedBy: .Equal, toItem: paper, attribute: .CenterY, multiplier: 1.0, constant: 0)
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
        prompt2Label.textAlignment = .Center
        prompt2Label.textColor = UIColor.whiteColor()
        prompt2Label.font = UIFont(name: "PT Sans", size: 24)

        let topY = NSLayoutConstraint(item: prompt2Label, attribute: .Top, relatedBy: .Equal, toItem: contentView, attribute: .Top, multiplier: 1, constant: -90)
        let width = NSLayoutConstraint(item: prompt2Label, attribute: .Width, relatedBy: .Equal, toItem: .None, attribute: .NotAnAttribute, multiplier: 1, constant: view.bounds.width - 100)
        contentView.addConstraints([topY, width])

        let slide = ConstraintConstantAnimation(superview: contentView, constraint: topY)
        slide[0] = -90
        slide[1] = 90
        animator.addAnimation(slide)

        keepView(prompt2Label, onPages: [0,1])
    }

    func setupExpense1() {
        contentView.addSubview(expense1)

        let height = NSLayoutConstraint(item: expense1, attribute: .Height, relatedBy: .Equal, toItem: envelopeBack, attribute: .Height, multiplier: 0.8, constant: 0)
        contentView.addConstraint(height)
        let width = NSLayoutConstraint(item: expense1, attribute: .Width, relatedBy: .Equal, toItem: paper, attribute: .Height, multiplier: 0.77381, constant: 0)
        contentView.addConstraint(width)
        let centerY = NSLayoutConstraint(item: expense1, attribute: .CenterY, relatedBy: .Equal, toItem: contentView, attribute: .CenterY, multiplier: 0.75, constant: 0)
        contentView.addConstraints([width, height, centerY])
        contentView.sendSubviewToBack(expense1)

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

        let topY = NSLayoutConstraint(item: fries, attribute: .Top, relatedBy: .Equal, toItem: prompt2Label, attribute: .Bottom, multiplier: 1, constant: 40)
        let friesHeight = NSLayoutConstraint(item: fries, attribute: .Height, relatedBy: .Equal, toItem: .None, attribute: .NotAnAttribute, multiplier: 1, constant: 120)
        let friesWidth = NSLayoutConstraint(item: fries, attribute: .Width, relatedBy: .Equal, toItem: fries, attribute: .Height, multiplier: 0.65182, constant: 0)
        contentView.addConstraints([topY, friesHeight, friesWidth])

        let slide = ConstraintConstantAnimation(superview: contentView, constraint: topY)
        slide[0] = 130
        slide[1] = 40
        animator.addAnimation(slide)

        keepView(fries, onPages: [1.07])

        contentView.addSubview(burger)

        let bottomY = NSLayoutConstraint(item: burger, attribute: .Bottom, relatedBy: .Equal, toItem: fries, attribute: .Bottom, multiplier: 1, constant: 0)
        let burgerWidth = NSLayoutConstraint(item: burger, attribute: .Width, relatedBy: .Equal, toItem: fries, attribute: .Width, multiplier: 1.47826, constant: 0)
        let burgerHeight = NSLayoutConstraint(item: burger, attribute: .Height, relatedBy: .Equal, toItem: burger, attribute: .Width, multiplier: 0.76891, constant: 0)
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
        prompt3Label.textAlignment = .Center
        prompt3Label.textColor = UIColor.whiteColor()
        prompt3Label.font = UIFont(name: "PT Sans", size: 24)

        let topY = NSLayoutConstraint(item: prompt3Label, attribute: .Top, relatedBy: .Equal, toItem: contentView, attribute: .Top, multiplier: 1, constant: -90)
        let width = NSLayoutConstraint(item: prompt3Label, attribute: .Width, relatedBy: .Equal, toItem: .None, attribute: .NotAnAttribute, multiplier: 1, constant: view.bounds.width - 100)
        contentView.addConstraints([topY, width])

        let slide = ConstraintConstantAnimation(superview: contentView, constraint: topY)
        slide[1] = -90
        slide[2] = 90
        animator.addAnimation(slide)

        keepView(prompt3Label, onPages: [1, 2])
    }

    func setupExpense2() {
        contentView.addSubview(expense2)

        let height = NSLayoutConstraint(item: expense2, attribute: .Height, relatedBy: .Equal, toItem: envelopeBack, attribute: .Height, multiplier: 0.8, constant: 0)
        let width = NSLayoutConstraint(item: expense2, attribute: .Width, relatedBy: .Equal, toItem: paper, attribute: .Height, multiplier: 0.77381, constant: 0)
        let centerY = NSLayoutConstraint(item: expense2, attribute: .CenterY, relatedBy: .Equal, toItem: contentView, attribute: .CenterY, multiplier: 0.75, constant: 0)
        contentView.addConstraints([width, height, centerY])
        contentView.sendSubviewToBack(expense2)

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
            letsGoBtn.enabled = false
            showAgainBtn.enabled = false
        }
        setupShowAgainPrompt()
    }

    func setupPrompt4() {
        contentView.addSubview(prompt4Label)

        prompt4Label.text = prompt4
        prompt4Label.numberOfLines = 0
        prompt4Label.textAlignment = .Center
        prompt4Label.textColor = UIColor.whiteColor()
        prompt4Label.font = UIFont(name: "PT Sans", size: 24)

        let topY = NSLayoutConstraint(item: prompt4Label, attribute: .Top, relatedBy: .Equal, toItem: contentView, attribute: .Top, multiplier: 1, constant: -90)
        let width = NSLayoutConstraint(item: prompt4Label, attribute: .Width, relatedBy: .Equal, toItem: .None, attribute: .NotAnAttribute, multiplier: 1, constant: view.bounds.width - 100)
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
        showAgainText.textAlignment = .Left
        showAgainText.textColor = .lightGrayColor()
        showAgainText.font = UIFont(name: "PT Sans", size: 20)

        let centerY = NSLayoutConstraint(item: showAgainText, attribute: .CenterY, relatedBy: .Equal, toItem: showAgainBtn, attribute: .CenterY, multiplier: 1, constant: 0)
        contentView.addConstraints([centerY])

        keepView(showAgainText, onPages: [2, 3.05], atTimes: [2, 3])
    }

    func setupShowAgainBtn() {
        contentView.addSubview(showAgainBtn)
        showAgainBtn.lineWidth = 1.5
        showAgainBtn.ringAlpha = 0.2
        showAgainBtn.strokeColor = .greenColor()
        showAgainBtn.addTarget(self, action: #selector(TutorialViewController.didTapOnOffButton), forControlEvents: .TouchUpInside)

        let topY = NSLayoutConstraint(item: showAgainBtn, attribute: .Top, relatedBy: .Equal, toItem: letsGoBtn, attribute: .Bottom, multiplier: 1, constant: 8)
        let width = NSLayoutConstraint(item: showAgainBtn, attribute: .Width, relatedBy: .Equal, toItem: .None, attribute: .NotAnAttribute, multiplier: 1, constant: 42)
        let height = NSLayoutConstraint(item: showAgainBtn, attribute: .Height, relatedBy: .Equal, toItem: showAgainBtn, attribute: .Height, multiplier: 1, constant: 0)

        contentView.addConstraints([topY, width, height])

        keepView(showAgainBtn, onPages: [2, 2.75], atTimes: [2, 3])
    }

    func didTapOnOffButton() {
        showAgainBtn.checked = !showAgainBtn.checked
        if (showAgainBtn.checked) {
            showAgainBtn.strokeColor = .greenColor()
        } else {
            showAgainBtn.strokeColor = .lightGrayColor()
        }
    }

    func setupLetsGoBtn() {
        contentView.addSubview(letsGoBtn)
        letsGoBtn.setTitle("Let's Go!", forState: .Normal)
        letsGoBtn.setTitle("Let's Go!", forState: .Selected)
        letsGoBtn.titleLabel?.font = UIFont(name: "PT Sans", size: 30)
        letsGoBtn.tintColor = UIColor(r: 255, g: 255, b: 255, alpha: 0.4)
        letsGoBtn.cornerRadius = 39
        letsGoBtn.selected = true

        let topY = NSLayoutConstraint(item: letsGoBtn, attribute: .Top, relatedBy: .Equal, toItem: envelopeBack, attribute: .Bottom, multiplier: 1, constant: 48)
        let width = NSLayoutConstraint(item: letsGoBtn, attribute: .Width, relatedBy: .Equal, toItem: .None, attribute: .NotAnAttribute, multiplier: 1, constant: 200)
        let height = NSLayoutConstraint(item: letsGoBtn, attribute: .Height, relatedBy: .Equal, toItem: .None, attribute: .NotAnAttribute, multiplier: 1, constant: 80)

        letsGoBtn.addTarget(self, action: #selector(TutorialViewController.didTapLetsGoBtn), forControlEvents: .TouchUpInside)

        contentView.addConstraints([topY, width, height])

        keepView(letsGoBtn, onPages: [2,3])
    }

    func didTapLetsGoBtn() {
        try! realm.write({
            settings.showTutorial = showAgainBtn.checked
        })
        let nextVC = storyboard?.instantiateViewControllerWithIdentifier("mainAppRootTabController") as! CustomTabViewController
        self.presentViewController(nextVC, animated: true, completion: nil)
    }
}

public class PageControlUpdater: Animation<CGFloat>, Animatable {
    
    private let pageControl : UIPageControl
    
    public init(pageControl: UIPageControl) {
        self.pageControl = pageControl
    }
    
    public override func validateValue(value: CGFloat) -> Bool {
        return (value >= 0) && (Int(value) <= pageControl.numberOfPages)
    }
    
    public func animate(time: CGFloat) {
        if !hasKeyframes() {return}
        pageControl.currentPage = Int(time)
        pageControl.updateCurrentPageDisplay()
    }
}












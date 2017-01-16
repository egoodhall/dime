//
//  ExpenseImageViewController.swift
//  Send Money
//
//  Created by Eric Marshall on 8/4/15.
//  Copyright (c) 2015 Eric Marshall. All rights reserved.
//

import UIKit

class ExpenseImageViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    /**
    Present options for changing the current image
    
    :param: sender: The calling UIBarButtonItem
    */
    @IBAction func changePicture(sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Select Image Source", message: nil, preferredStyle: .ActionSheet)
        
        alert.addAction(UIAlertAction(title: "Clear Image", style: .Destructive){ (Action) in
            self.image = UIImage(named: "addPhoto")
            self.performSegueWithIdentifier("doneWithImageSegue", sender: self)
            })
        alert.addAction(UIAlertAction(title: "Camera", style: .Default){ (Action) in
            self.getPhoto(true)
            })
        alert.addAction(UIAlertAction(title: "Photo Library", style: .Default){ (Action) in
            self.getPhoto(false)
            })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }

    /// The main image view in the ExpenseImageViewController
    @IBOutlet weak var imageView: UIImageView!

    /// The image contained within the current Expense
    var image: UIImage!
    /// Whether or not the user can change the image
    var allowImageEditing = true

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = image
        
        self.navigationItem.title = "Image"
        if (allowImageEditing) {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Camera, target: self, action: #selector(ExpenseImageViewController.changePicture(_:)))
        }

    }

    /**
    Get an image for the current Expense
    
    :param: fromCamera: whether or not the image will come from the camera
    */
    func getPhoto(fromCamera: Bool) {
        let imgPicker = UIImagePickerController()
        imgPicker.allowsEditing = true
        if fromCamera {
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera){
                imgPicker.sourceType = .Camera
                imgPicker.shouldAutorotate()
                imgPicker.showsCameraControls = true
            }
        } else {
            if UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary){
                imgPicker.sourceType = .PhotoLibrary
            }
        }
        imgPicker.delegate = self
        imgPicker.allowsEditing = false
        self.presentViewController(imgPicker, animated: true, completion: nil)
    }

    
    //------------------------------
    // MARK: - Image picker delegate
    //------------------------------
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            print(pickedImage.imageOrientation.rawValue)
            
            let croppedImage = scaleAndRotateImage(pickedImage)
            
            print(croppedImage.imageOrientation.rawValue)
            
            self.image = croppedImage
            
            self.imageView.image = croppedImage

            self.dismissViewControllerAnimated(true, completion: {
                    self.performSegueWithIdentifier("doneWithImageSegue", sender: self)
            })
        }
    }

    /**
    Scale and rotate a UIImage so that it is correctly oriented
    
    :param: image: The image to be rotated
    
    :returns: UIImage
    */
    func scaleAndRotateImage(image: UIImage) -> UIImage {
        let kMaxResolution: CGFloat = 640
        let imgRef: CGImageRef = image.CGImage!
        let width: CGFloat = CGFloat(CGImageGetWidth(imgRef))
        let height: CGFloat = CGFloat(CGImageGetHeight(imgRef))
        var transform: CGAffineTransform = CGAffineTransformIdentity
        var bounds: CGRect = CGRectMake(0, 0, width, height)
        if width > kMaxResolution || height > kMaxResolution {
            let ratio: CGFloat = width / height
            if ratio > 1 {
                bounds.size.width = kMaxResolution
                bounds.size.height = (bounds.size.width / ratio)
            }
            else {
                bounds.size.height = kMaxResolution
                bounds.size.width = (bounds.size.height * ratio)
            }
        }
        let scaleRatio: CGFloat = bounds.size.width / width
        let imageSize: CGSize = CGSizeMake(CGFloat(CGImageGetWidth(imgRef)), CGFloat(CGImageGetHeight(imgRef)))
        var boundHeight: CGFloat
        let orient: UIImageOrientation = image.imageOrientation
        switch orient {
        case UIImageOrientation.Up:
            transform = CGAffineTransformIdentity
        case UIImageOrientation.UpMirrored:
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0)
            transform = CGAffineTransformScale(transform, -1.0, 1.0)
        case UIImageOrientation.Down:
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI))
        case UIImageOrientation.DownMirrored:
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height)
            transform = CGAffineTransformScale(transform, 1.0, -1.0)
        case UIImageOrientation.LeftMirrored:
            boundHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundHeight
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width)
            transform = CGAffineTransformScale(transform, -1.0, 1.0)
            transform = CGAffineTransformRotate(transform, CGFloat(3.0 * M_PI / 2.0))
        case UIImageOrientation.Left:
            boundHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundHeight
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width)
            transform = CGAffineTransformRotate(transform, CGFloat(3.0 * M_PI / 2.0))
        case UIImageOrientation.RightMirrored:
            boundHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundHeight
            transform = CGAffineTransformMakeScale(-1.0, 1.0)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI / 2.0))
        case UIImageOrientation.Right:
            boundHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundHeight
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI / 2.0))
        }
        UIGraphicsBeginImageContext(bounds.size)
        let context: CGContextRef = UIGraphicsGetCurrentContext()!
        if orient == UIImageOrientation.Right || orient == UIImageOrientation.Left {
            CGContextScaleCTM(context, -scaleRatio, scaleRatio)
            CGContextTranslateCTM(context, -height, 0)
        }
        else {
            CGContextScaleCTM(context, scaleRatio, -scaleRatio)
            CGContextTranslateCTM(context, 0, -height)
        }
        CGContextConcatCTM(context, transform)
        CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef)
        let imageCopy: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return imageCopy
    }


    //-------------------
    // MARK: - Navigation
    //-------------------
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "doneWithImageSegue" {
            let destVC = segue.destinationViewController as! NewExpenseTableViewController
            destVC.expenseImage.image = self.image
            if self.image == UIImage(named: "addPhoto") {
                destVC.imageIsDefault = true
            }
        }
    }
}

//
//  ExpenseImageViewController.swift
//  Send Money
//
//  Created by Eric Marshall on 8/4/15.
//  Copyright (c) 2015 Eric Marshall. All rights reserved.
//

import UIKit

class ExpenseImageViewController: UIViewController, UIImagePickerControllerDelegate {

    /**
    Present options for changing the current image
    
    :param: sender: The calling UIBarButtonItem
    */
    @IBAction func changePicture(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Select Image Source", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Clear Image", style: .destructive){ (Action) in
            self.image = UIImage(named: "addPhoto")
            self.performSegue(withIdentifier: "doneWithImageSegue", sender: self)
            })
        alert.addAction(UIAlertAction(title: "Camera", style: .default){ (Action) in
            self.getPhoto(true)
            })
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default){ (Action) in
            self.getPhoto(false)
            })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
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
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(ExpenseImageViewController.changePicture(_:)))
        }

    }

    /**
    Get an image for the current Expense
    
    :param: fromCamera: whether or not the image will come from the camera
    */
    func getPhoto(_ fromCamera: Bool) {
        let imgPicker = UIImagePickerController()
        imgPicker.allowsEditing = true
        if fromCamera {
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera){
                imgPicker.sourceType = .camera
                imgPicker.showsCameraControls = true
            }
        } else {
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
                imgPicker.sourceType = .photoLibrary
            }
        }
        imgPicker.delegate = self
        imgPicker.allowsEditing = false
        self.present(imgPicker, animated: true, completion: nil)
    }

    
    //------------------------------
    // MARK: - Image picker delegate
    //------------------------------
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            print(pickedImage.imageOrientation.rawValue)
            
            let croppedImage = scaleAndRotateImage(pickedImage)
            
            print(croppedImage.imageOrientation.rawValue)
            
            self.image = croppedImage
            
            self.imageView.image = croppedImage

            self.dismiss(animated: true, completion: {
                    self.performSegue(withIdentifier: "doneWithImageSegue", sender: self)
            })
        }
    }

    /**
    Scale and rotate a UIImage so that it is correctly oriented
    
    :param: image: The image to be rotated
    
    :returns: UIImage
    */
    func scaleAndRotateImage(_ image: UIImage) -> UIImage {
        let kMaxResolution: CGFloat = 640
        let imgRef: CGImage = image.cgImage!
        let width: CGFloat = CGFloat(imgRef.width)
        let height: CGFloat = CGFloat(imgRef.height)
        var transform: CGAffineTransform = CGAffineTransform.identity
        var bounds: CGRect = CGRect(x: 0, y: 0, width: width, height: height)
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
        let imageSize: CGSize = CGSize(width: CGFloat(imgRef.width), height: CGFloat(imgRef.height))
        var boundHeight: CGFloat
        let orient: UIImageOrientation = image.imageOrientation
        switch orient {
        case UIImageOrientation.up:
            transform = CGAffineTransform.identity
        case UIImageOrientation.upMirrored:
            transform = CGAffineTransform(translationX: imageSize.width, y: 0.0)
            transform = transform.scaledBy(x: -1.0, y: 1.0)
        case UIImageOrientation.down:
            transform = CGAffineTransform(translationX: imageSize.width, y: imageSize.height)
            transform = transform.rotated(by: CGFloat(Double.pi))
        case UIImageOrientation.downMirrored:
            transform = CGAffineTransform(translationX: 0.0, y: imageSize.height)
            transform = transform.scaledBy(x: 1.0, y: -1.0)
        case UIImageOrientation.leftMirrored:
            boundHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundHeight
            transform = CGAffineTransform(translationX: imageSize.height, y: imageSize.width)
            transform = transform.scaledBy(x: -1.0, y: 1.0)
            transform = transform.rotated(by: CGFloat(3.0 * .pi / 2.0))
        case UIImageOrientation.left:
            boundHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundHeight
            transform = CGAffineTransform(translationX: 0.0, y: imageSize.width)
            transform = transform.rotated(by: CGFloat(3.0 * .pi / 2.0))
        case UIImageOrientation.rightMirrored:
            boundHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundHeight
            transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
            transform = transform.rotated(by: CGFloat(.pi / 2.0))
        case UIImageOrientation.right:
            boundHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundHeight
            transform = CGAffineTransform(translationX: imageSize.height, y: 0.0)
            transform = transform.rotated(by: CGFloat(.pi / 2.0))
        }
        UIGraphicsBeginImageContext(bounds.size)
        let context: CGContext = UIGraphicsGetCurrentContext()!
        if orient == UIImageOrientation.right || orient == UIImageOrientation.left {
            context.scaleBy(x: -scaleRatio, y: scaleRatio)
            context.translateBy(x: -height, y: 0)
        }
        else {
            context.scaleBy(x: scaleRatio, y: -scaleRatio)
            context.translateBy(x: 0, y: -height)
        }
        context.concatenate(transform)
        UIGraphicsGetCurrentContext()?.draw(imgRef, in: CGRect(x: 0, y: 0, width: width, height: height))
        let imageCopy: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return imageCopy
    }


    //-------------------
    // MARK: - Navigation
    //-------------------
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "doneWithImageSegue" {
            let destVC = segue.destination as! NewExpenseTableViewController
            destVC.expenseImage.image = self.image
            if self.image == UIImage(named: "addPhoto") {
                destVC.imageIsDefault = true
            }
        }
    }
}

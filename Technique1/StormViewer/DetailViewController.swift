//
//  DetailViewController.swift
//  StormViewer
//
//  Created by Timothy on 02/05/2023.
//

import UIKit

class DetailViewController: UIViewController {
    @IBOutlet var imageView: UIImageView!
    var selectedImage: String?
    
    var selectedImageNumber = 0
    var totalNumberOfImages = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = selectedImage
        
        // on the left we're assigning to the rightBarButtonItem of our view controller's navigationItem. This navigation item is used by the navigation bar so that it can show relevant information. In this case, we're setting the right bar button item, which is a button that appears on the right of the navigation bar when this view controller is visible.
        
        // On the right we create a new instance of the UIBarButtonItem data type, setting it up with three parameters: a system item, a target, and an action. The system item we specify is .action, but you can type . to have code completion tell you the many other options available. The .action system item displays an arrow coming out of a box, signaling the user can do something when it's tapped.

        // The target and action parameters go hand in hand, because combined they tell the UIBarButtonItem what method should be called. The action parameter is saying "when you're tapped, call the shareTapped() method," and the target parameter tells the button that the method belongs to the current view controller – self.
        
        // The part in #selector bears explaining a bit more, because it's new and unusual syntax. What it does is tell the Swift compiler that a method called "shareTapped" will exist, and should be triggered when the button is tapped. Swift will check this for you: if we had written "shareTaped" by accident – missing the second P – Xcode will refuse to build our app until we fix the typo.

        // If you don't like the look of the various system bar button items available, you can create one with your own title or image instead. However, it's generally preferred to use the system items where possible because users already know what they do.
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareTapped))

        // Do any additional setup after loading the view.
        if let imageToLoad = selectedImage {
            imageView.image = UIImage(named: imageToLoad)
        }
        
        navigationItem.largeTitleDisplayMode = .never
    }
    
    // We're using override for each of these methods, because they already have defaults defined in UIViewController and we're asking it to use ours instead. Don't worry if you aren't sure when to use override and when not, because if you don't use it and it's required Xcode will tell you.
    // Both methods have a single parameter: whether the action is animated or not. We don't really care in this instance, so we ignore it.
    // Both methods use the super prefix again: super.viewWillAppear() and super.viewWillDisappear(). This means "tell my parent data type that these methods were called." In this instance, it means that it passes the method on to UIViewController, which may do its own processing.
    // We’re using the navigationController property again, which will work fine because we were pushed onto the navigation controller stack from ViewController. We’re accessing the property using ?, so if somehow we weren’t inside a navigation controller the hidesBarsOnTap lines will do nothing.//
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.hidesBarsOnTap = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.hidesBarsOnTap = false
    }
    
    // We start with the method name, marked with @objc because this method will get called by the underlying Objective-C operating system (the UIBarButtonItem) so we need to mark it as being available to Objective-C code. When you call a method using #selector you’ll always need to use @objc too.
    @objc func shareTapped() {
        guard let image = imageView.image?.jpegData(compressionQuality: 0.8) else {
            print("No image found.")
            return
        }
        
        // Our image view may or may not have an image inside, so we’ll read it out safely and convert it to JPEG data. This has a compressionQuality parameter where you can specify a value between 1.0 (maximum quality) and 0.0 (minimum quality_.
        // Next we create a UIActivityViewController, which is the iOS method of sharing content with other apps and services.
        // Finally, we tell iOS where the activity view controller should be anchored – where it should appear from.
        let vc = UIActivityViewController(activityItems: [image, selectedImage!], applicationActivities: [])
        vc.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(vc, animated: true)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

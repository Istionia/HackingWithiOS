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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.hidesBarsOnTap = false
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

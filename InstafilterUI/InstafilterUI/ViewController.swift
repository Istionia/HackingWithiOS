//
//  ViewController.swift
//  InstafilterUI
//
//  Created by Timothy on 22/05/2023.
//

import UIKit
import CoreImage

class ViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var intensity: UISlider!
    
    var currentImage: UIImage!
    
    // Core Image context, which is the Core Image component that handles rendering
    // We create it here and use it throughout our app, because creating a context is computationally expensive so we don't want to keep doing it.
    var context: CIContext!
    // Core Image filter, and will store whatever filter the user has activated.
    // This filter will be given various input settings before we ask it to output a result for us to show in the image view.
    var currentFilter: CIFilter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        title = "Instafilter"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(importPicture))
        
        context = CIContext()
        currentFilter = CIFilter(name: "CISepiaTone")
    }

    @IBAction func changeFilter(_ sender: UIButton) {
        let ac = UIAlertController(title: "Choose filter", message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "CIBumpDistortion", style: .default, handler: setFilter))
        ac.addAction(UIAlertAction(title: "CIGaussianBlur", style: .default, handler: setFilter))
        ac.addAction(UIAlertAction(title: "CIPixellate", style: .default, handler: setFilter))
        ac.addAction(UIAlertAction(title: "CISepiaTone", style: .default, handler: setFilter))
        ac.addAction(UIAlertAction(title: "CITwirlDistortion", style: .default, handler: setFilter))
        ac.addAction(UIAlertAction(title: "CIUnsharpMask", style: .default, handler: setFilter))
        ac.addAction(UIAlertAction(title: "CIVignette", style: .default, handler: setFilter))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popoverController = ac.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds
        }
            
        present(ac, animated: true)
    }
    
    @IBAction func save(_ sender: Any) {
        guard let image = imageView.image else { return }
        
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_: didFinishSavingWithError: contextInfo:)), nil)
    }
    
    @IBAction func intensityChanged(_ sender: Any) {
        applyProcessing()
    }
    
    func applyProcessing() {
        let inputKeys = currentFilter.inputKeys
        
        // Using this method, we check each of our four keys to see whether the current filter supports it, and, if so, we set the value. The first three all use the value from our intensity slider in some way, which will produce some interesting results. If you wanted to improve this app later, you could perhaps add three sliders.
        if inputKeys.contains(kCIInputIntensityKey) { currentFilter.setValue(intensity.value, forKey: kCIInputIntensityKey)
        }
        
        if inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(intensity.value * 20, forKey: kCIInputRadiusKey)
        }
        
        if inputKeys.contains(kCIInputScaleKey) { currentFilter.setValue(intensity.value * 10, forKey: kCIInputScaleKey)
        }
        
        if inputKeys.contains(kCIInputCenterKey) { currentFilter.setValue(CIVector(x: currentImage.size.width, y: currentImage.size.height / 2), forKey: kCIInputCenterKey)
        }
        
        // The first line safely reads the output image from our current filter. This should always exist, but there’s no harm being safe.
        // The second line uses the value of our intensity slider to set the kCIInputIntensityKey value of our current Core Image filter. For sepia toning a value of 0 means "no effect" and 1 means "fully sepia."
        // The third line is where the hard work happens: it creates a new data type called CGImage from the output image of the current filter. We need to specify which part of the image we want to render, but using image.extent means "all of it." Until this method is called, no actual processing is done, so this is the one that does the real work. This returns an optional CGImage so we need to check and unwrap with if let.
        // The fourth line creates a new UIImage from the CGImage, and line five assigns that UIImage to our image view. Yes, I know that UIImage, CGImage and CIImage all sound the same, but they are different under the hood and we have no choice but to use them here.
        if let cgImage = context.createCGImage(currentFilter.outputImage!, from: currentFilter.outputImage!.extent) {
            let processedImage = UIImage(cgImage: cgImage)
            imageView.image = processedImage
        }
    }
    
    @objc func importPicture() {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        
        dismiss(animated: true)
        
        // where we set our currentImage image to be the one selected in the image picker? This is required so that we can have a copy of what was originally imported. Whenever the user changes filter, we need to put that original image back into the filter.
        currentImage = image
        
        // The CIImage data type is, for the sake of this project, just the Core Image equivalent of UIImage. Behind the scenes it's a bit more complicated than that, but really it doesn't matter.
        // As you can see, we can create a CIImage from a UIImage, and we send the result into the current Core Image Filter using the kCIInputImageKey. There are lots of Core Image key constants like this; at least this one is somewhat self-explanatory!
        let beginImage = CIImage(image: currentImage)
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        applyProcessing()
    }
    
    func setFilter(action: UIAlertAction) {
        // make sure we have a valid image before continuing!
        guard currentImage != nil else { return }

        // safely read the alert action's title
        guard let actionTitle = action.title else { return }

        currentFilter = CIFilter(name: actionTitle)

        let beginImage = CIImage(image: currentImage)
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)

        applyProcessing()
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error : Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
        
        // Try making the Save button show an error if there was no image in the image view
        if imageView == nil {
            // we've got an error!
            let ac = UIAlertController(title: "No image!", message: error?.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
}


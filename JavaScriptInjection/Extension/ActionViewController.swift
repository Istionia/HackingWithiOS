//
//  ActionViewController.swift
//  Extension
//
//  Created by Timothy on 28/05/2023.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

class ActionViewController: UIViewController {
    @IBOutlet var script: UITextView!
    
    var pageTitle = ""
    var pageURL = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        // When our extension is created, its extensionContext lets us control how it interacts with the parent app. In the case of inputItems this will be an array of data the parent app is sending to our extension to use. We only care about this first item in this project, and even then it might not exist, so we conditionally typecast using if let and as?.
        if let inputItem = extensionContext?.inputItems.first as? NSExtensionItem {
            // Our input item contains an array of attachments, which are given to us wrapped up as an NSItemProvider. Our code pulls out the first attachment from the first input item.
            if let itemProvider = inputItem.attachments?.first {
                itemProvider
                // The next line uses loadItem(forTypeIdentifier: ) to ask the item provider to actually provide us with its item, but you'll notice it uses a closure so this code executes asynchronously. That is, the method will carry on executing while the item provider is busy loading and sending us its data.
                    .loadItem(forTypeIdentifier:
                                // Inside our closure we first need the usual [weak self] to avoid strong reference cycles, but we also need to accept two parameters: the dictionary that was given to us by the item provider, and any error that occurred.
                              itemProvider.loadItem(forTypeIdentifier: UTType.propertyList.identifier as String) as! String) {[weak self] (dict, error) in
                    // With the item successfully pulled out, we can get to the interesting stuff: working with the data.
                        // NSDictionary is a new data type, and it’s not really one you have much cause to use in Swift that often because it’s a bit of a holdover from older iOS code. Put simply, NSDictionary works like a Swift dictionary, except you don't need to declare or even know what data types it holds. One of the nasty things about NSDictionary is that you don't need to declare or even know what data types it holds.
                        // Yes, it's both an advantage and a disadvantage in one, which is why modern Swift dictionaries are preferred. When working with extensions, however, it's definitely an advantage because we just don't care what's in there – we just want to pull out our data.
                        // When you use loadItem(forTypeIdentifier:), your closure will be called with the data that was received from the extension along with any error that occurred. Apple could provide other data too, so what we get is a dictionary of data that contains all the information Apple wants us to have, and we put that into itemDictionary.
                        // Right now, there's nothing in that dictionary other than the data we sent from JavaScript, and that's stored in a special key called NSExtensionJavaScriptPreprocessingResultsKey. So, we pull that value out from the dictionary, and put it into a value called javaScriptValues.
                        // We sent a dictionary of data from JavaScript, so we typecast javaScriptValues as an NSDictionary again so that we can pull out values using keys, but for now we just send the whole lot to the print() function, which dumps the dictionary contents to Xcode's debug console.
                        guard let itemDictionary = dict as? NSDictionary else {
                            return
                        }
                        
                        guard let javaScriptValues = itemDictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary else {
                            return
                        }
                        // That sets our two properties from the javaScriptValues dictionary, typecasting them as String. It then uses async() to set the view controller's title property on the main queue. This is needed because the closure being executed as a result of loadItem(forTypeIdentifier:) could be called on any thread, and we don't want to change the UI unless we're on the main thread.
                        // You might have noticed that I haven't written [weak self] in for the async() call, and that's because it's not needed. The closure will capture the variables it needs, which includes self, but we're already inside a closure that has declared self to be weak, so this new closure will use that.
                        self?.pageTitle = javaScriptValues["title"] as? String ?? ""
                        self?.pageURL = javaScriptValues["URL"] as? String ?? ""
                        
                        DispatchQueue.main.async {
                            self?.title = self?.pageTitle
                        }
                }
            }
        }
    }

    @IBAction func done() {
        // Create a new NSExtensionItem object that will host our items.
        let item = NSExtensionItem()
        // Create a dictionary containing the key "customJavaScript" and the value of our script.
        let argument: NSDictionary = ["customJavaScript": script.text as Any]
        // Put that dictionary into another dictionary with the key NSExtensionJavaScriptFinalizeArgumentKey.
        let webDictionary: NSDictionary = [NSExtensionJavaScriptFinalizeArgumentKey: argument]
        // Wrap the big dictionary inside an NSItemProvider object with the type identifier kUTTypePropertyList.
        let customJavaScript = NSItemProvider(item: webDictionary, typeIdentifier: kUTTypePropertyList as String)
        // Place that NSItemProvider into our NSExtensionItem as its attachments.
        item.attachments = [customJavaScript]

        // Call completeRequest(returningItems:), returning our NSExtensionItem.
        extensionContext?.completeRequest(returningItems: [item])
    }
    // The code in done() is really just the reverse of what we are doing inside viewDidLoad().
    // That's all the code required to send data back to Safari, at which point it will appear inside the finalize() function in Action.js. From there we can do what we like with it, but in this project the JavaScript we need to write is remarkably simple: we pull the "customJavaScript" value out of the parameters array, then pass it to the JavaScript eval() function, which executes any code it finds.
    
    // The adjustForKeyboard() method is complicated, but that's because it has quite a bit of work to do. First, it will receive a parameter that is of type Notification. This will include the name of the notification as well as a Dictionary containing notification-specific information called userInfo.
    @objc func adjustForKeyboard(notification: Notification) {
        // When working with keyboards, the dictionary will contain a key called UIResponder.keyboardFrameEndUserInfoKey telling us the frame of the keyboard after it has finished animating. This will be of type NSValue, which in turn is of type CGRect. The CGRect struct holds both a CGPoint and a CGSize, so it can be used to describe a rectangle.
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        
        // One of the quirks of Objective-C was that arrays and dictionaries couldn't contain structures like CGRect, so Apple had a special class called NSValue that acted as a wrapper around structures so they could be put into dictionaries and arrays. That's what's happening here: we're getting an NSValue object, but we know it contains a CGRect inside so we use its cgRectValue property to read that value.
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        // Once we finally pull out the correct frame of the keyboard, we need to convert the rectangle to our view's co-ordinates. This is because rotation isn't factored into the frame, so if the user is in landscape we'll have the width and height flipped – using the convert() method will fix that.
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        // The next thing we need to do in the adjustForKeyboard() method is to adjust the contentInset and scrollIndicatorInsets of our text view. These two essentially indent the edges of our text view so that it appears to occupy less space even though its constraints are still edge to edge in the view.
        // Note there's a check in there for UIKeyboardWillHide, and that's the workaround for hardware keyboards being connected by explicitly setting the insets to be zero.
        if notification.name == UIResponder.keyboardWillHideNotification {
            script.contentInset = .zero
        } else {
            // As you can see, setting the inset of a text view is done using the UIEdgeInsets struct, which needs insets for all four edges. I'm using the text view's content inset for its scrollIndicatorInsets to save time.
            script.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }
        
        // Finally, we're going to make the text view scroll so that the text entry cursor is visible. If the text view has shrunk this will now be off screen, so scrolling to find it again keeps the user experience intact.
        script.scrollIndicatorInsets = script.contentInset
        
        let selectedRange = script.selectedRange
        script.scrollRangeToVisible(selectedRange)
    }
}

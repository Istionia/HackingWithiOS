//
//  ViewController.swift
//  Secret Swift
//
//  Created by Timothy on 05/06/2023.
//

import UIKit
import LocalAuthentication

class ViewController: UIViewController {
    @IBOutlet var secret: UITextView!
    
    @IBOutlet var authenticateTapped: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // As a reminder, that asks iOS to tell us when the keyboard changes or when it hides. As a double reminder: the hide is required because we do a little hack to make the hardware keyboard toggle work correctly.
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        // calls our saveSecretMessage() directly when the notification comes in, which means the app automatically saves any text and hides it when the app is moving to a background state
        notificationCenter.addObserver(self, selector: #selector(saveSecretMessage), name: UIApplication.willResignActiveNotification, object: nil)
        
        title = "Nothing to see here"
    }

    // identical to JS Injection, apart from the outlet's name
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            secret.contentInset = .zero
        } else {
            secret.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }
        
        secret.scrollIndicatorInsets = secret.contentInset
        
        let selectedRange = secret.selectedRange
        secret.scrollRangeToVisible(selectedRange)
    }
    
    func unlockSecretMessage() {
        secret.isHidden = false
        title = "Secret Stuff"
        
        secret.text = KeychainWrapper.standard.string(forKey: "SecretMessage")
    }
    
    @objc func saveSecretMessage() {
        guard secret.isHidden == false else {
            return
        }
        
        KeychainWrapper.standard.set(secret.text, forKey: "SecretMessage")
        // This is used to tell a view that has input focus that it should give up that focus. Or, in Plain English, to tell our text view that we're finished editing it, so the keyboard can be hidden. This is important because having a keyboard present might arouse suspicion – as if our rather obvious navigation bar title hadn't done enough already…
        secret.resignFirstResponder()
        secret.isHidden = true
        title = "Nothing to see here"
    }
    
    // There is one important new piece of syntax in there that we haven’t used before, which is &error. The LocalAuthentication framework uses the Objective-C approach to reporting errors back to us, which is where the NSError type comes from – where Swift likes to have an enum that conforms to the Error protocol, Objective-C had a dedicated NSError type for handling errors.
    // Here, though, we want LocalAuthentication to tell us what went wrong, and it can’t do that by returning a value from the canEvaluatePolicy() method – that already returns a Boolean telling us whether biometric authentication is available or not. So, instead what we use is the Objective-C equivalent of Swift’s inout parameters: we pass an empty NSError variable into our call to canEvaluatePolicy(), and if an error occurs that error will get filled with a real NSError instance telling us what went wrong.
    // Objective-C’s equivalent to inout is what’s called a pointer, so named because it effectively points to a place in memory where something exists rather us passing around the actual value instead. If we had passed error into the method, it would mean “here’s the error you should use.” By passing in &error – Objective-C’s equivalent of inout – it means “if you hit an error, here’s the place in memory where you should store that error so I can read it.”
    @IBAction func authenticateTapped(_ sender: Any) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // You can see the “Identify yourself!” string in our code, which will be shown to Touch ID users. Face ID is handled slightly differently – open Info.plist, then add a new key called “Privacy - Face ID Usage Description”. This should contain similar text to what you use with Touch ID, so give it the value “Identify yourself!”.
            let reason = "Identify yourself!"

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                //  we need [weak self] inside the first closure but not the second because it's already weak by that point. You also need to use self?. inside the closure to make capturing clear. Finally, you must provide a reason why you want Touch ID/Face ID to be used, so you might want to replace mine ("Identify yourself!") with something a little more descriptive.
                [weak self] success, authenticationError in

                DispatchQueue.main.async {
                    if success {
                        self?.unlockSecretMessage()
                    } else {
                        // error
                        let ac = UIAlertController(title: "Authentication failed", message: "You could not be verified; please try again.", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self?.present(ac, animated: true)
                    }
                }
            }
        } else {
            // no biometry
            let ac = UIAlertController(title: "Biometry unavailable", message: "Your device is not configured for biometric authentication.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(ac, animated: true)
        }
    }
}


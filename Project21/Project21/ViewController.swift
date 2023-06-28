//
//  ViewController.swift
//  Project21
//
//  Created by Timothy on 28/05/2023.
// First, you can't post messages to the user's lock screen unless you have their permission. This is a sensible restriction – it would, after all, be awfully annoying if any app could bother you when it pleased.
// So, in order to send local notifications in our app, we first need to request permission, and that's what we'll put in the registerLocal() method. You register your settings based on what you actually need, and that's done with a method called requestAuthorization() on UNUserNotificationCenter. For this example we're going to request an alert (a message to show), along with a badge (for our icon) and a sound (because users just love those.)
// You also need to provide a closure that will be executed when the user has granted or denied your permissions request. This will be given two parameters: a boolean that will be true if permission was granted, and an Error? containing a message if something went wrong.

import UIKit
import UserNotifications

class ViewController: UIViewController, UNUserNotificationCenterDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Register", style: .plain, target: self, action: #selector(registerLocal))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Schedule", style: .plain, target: self, action: #selector(scheduleLocal))
    }
    
    @objc func registerLocal() {
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.alert, .badge, .sound]) {(granted, error) in
            if granted {
                print("Yay!")
            } else {
                print("Oh, crap!")
            }
        }
    }
    
    @objc func scheduleLocal() {
        registerCategories()
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "Late wake up call"
        content.body = "The early bird catches the worm, but the second mouse gets the cheese."
        content.categoryIdentifier = "alarm"
        content.userInfo = ["customData": "fizzbuzz"]
        content.sound = UNNotificationSound.default
        
        // create a repeating alarm at 10:30 a.m.
        var dateComponents = DateComponents()
        dateComponents.hour = 10
        dateComponents.minute = 30
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        center.add(request)
        
        center.removeAllPendingNotificationRequests()
    }
    
    func registerCategories() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        let show = UNNotificationAction(identifier: "show", title: "Tell me more...", options: .foreground)
        // empty intentIdentifiers parameter in the category initializer - this is used to connect your notifications to intents, if you have created any
        let category = UNNotificationCategory(identifier: "alarm", actions: [show], intentIdentifiers: [])
        
        center.setNotificationCategories([category])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // pull out the buried userInfo dictionary
        let userInfo = response.notification.request.content.userInfo
        
        if let customData = userInfo["customData"] as? String {
            print("Custom data received: \(customData)")
            
            switch response.actionIdentifier {
            case UNNotificationDefaultActionIdentifier:
                // the user swiped to unlock
                print("Default identifier")
                
            case "show":
                // the user tapped our "show more info…" button
                print("Show more information...")
            default:
                break
            }
        }
        
        // you must call the completion handler when you're done
        completionHandler()
    }
}


//
//  ViewController.swift
//  SimpleBrowser
//
//  Created by Timothy on 11/05/2023.
//

import UIKit
import WebKit

// As you know, when we say class A: B we’re defining a new class called A that builds on the functionality provided by class B. However, when we say class A: B, C we’re saying it inherits from UIViewController (the first item in the list), and promises it implements the WKNavigationDelegate protocol.

// The order here really is important: the parent class (superclass) comes first, then all protocols implemented come next, all separated by commas. We're saying that we conform to only one protocol here (WKNavigationDelegate) but you can specify as many as you need to.

// So, the complete meaning of this line is "create a new subclass of UIViewController called ViewController, and tell the compiler that we promise we’re safe to use as a WKNavigationDelegate."
class ViewController: UITableViewController, WKNavigationDelegate {
    var webView: WKWebView!
    var progressView: UIProgressView!
    var websites = ["apple.com", "en.wikipedia.org/wiki/Main_Page", "google.com", "archiveofourown.org", "stackoverflow.com", "youtube.com", "daemonpage.com", "instagram.com", "twitter.com"]
    
    // You don’t need to put loadView() before viewDidLoad(), and in fact you could put it anywhere between class ViewController: UIViewController { down to the last closing brace in the file. However, I encourage you to structure your methods in an organized way, and because loadView() gets called before viewDidLoad() it makes sense to position the code above it too.
    // why we need to use the override keyword? it's because there's a default implementation, which is to load the layout from the storyboard.
    override func loadView() {
        // First, we create a new instance of Apple's WKWebView web browser component and assign it to the webView property.
        webView = WKWebView()
        // Delegation is what's called a programming pattern – a way of writing code – and it's used extensively in iOS. And for good reason: it's easy to understand, easy to use, and extremely flexible.

        // A delegate is one thing acting in place of another, effectively answering questions and responding to events on its behalf. In our example, we're using WKWebView: Apple's powerful, flexible and efficient web renderer. But as smart as WKWebView is, it doesn't know (or care) how our application wants to behave, because that's our custom code.

        // The delegation solution is brilliant: we can tell WKWebView that we want to be informed when something interesting happens. In our code, we're setting the web view's navigationDelegate property to self, which means "when any web page navigation happens, please tell me – the current view controller.”
        
        // When you do this, two things happen:

        // 1. You must conform to the protocol. This is a fancy way of saying, "if you're telling me you can handle being my delegate, here are the methods you need to implement." In the case of navigationDelegate, all these methods are optional, meaning that we don't need to implement any methods.
        // 2. Any methods you do implement will now be given control over the WKWebView's behavior. Any you don't implement will use the default behavior of WKWebView.
        webView.navigationDelegate = self
        // Third, we make our view (the root view of the view controller) that web view.
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let url = URL(string: "https://" + websites[0])!
        webView.load(URLRequest(url: url))
        webView.allowsBackForwardNavigationGestures = true
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Open", style: .plain, target: self, action: #selector(openTapped))
        
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        // creates a new UIProgressView instance, giving it the default style (There is an alternative style called .bar, which doesn't draw an unfilled line to show the extent of the progress view, but the default style looks best here)
        progressView = UIProgressView(progressViewStyle: .default)
        // tells the progress view to set its layout size so that it fits its contents fully
        progressView.sizeToFit()
        // creates a new UIBarButtonItem using the customView parameter, which is where we wrap up our UIProgressView in a UIBarButtonItem so that it can go into our toolbar
        let progressButton = UIBarButtonItem(customView: progressView)
        let refresh = UIBarButtonItem(barButtonSystemItem: .refresh, target: webView, action: #selector(webView.reload))
        let back = UIBarButtonItem(title: "Back", style: .plain, target: webView, action: #selector(webView.goBack))
        let forward = UIBarButtonItem(title: "Forward", style: .plain, target: webView, action: #selector(webView.goForward))
        
        // creates an array containing the flexible space and the refresh button, then sets it to be our view controller's toolbarItems array
        toolbarItems = [back, forward, progressButton, spacer, refresh]
        // sets the navigation controller's isToolbarHidden property to be false, so the toolbar will be shown – and its items will be loaded from our current view
        navigationController?.isToolbarHidden = false
        
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            progressView.progress = Float(webView.estimatedProgress)
        }
    }

    @objc func openTapped() {
        let ac = UIAlertController(title: "Open page", message: nil, preferredStyle: .actionSheet)
        for website in websites {
            ac.addAction(UIAlertAction(title: website, style: .default, handler: openPage))
        }
        ac.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
        present(ac, animated: true)
    }
    
    // What the method does is use the title property of the action (apple.com, hackingwithswift.com), put "https://" in front of it to satisfy App Transport Security, then construct a URL out of it. It then wraps that inside an URLRequest, and gives it to the web view to load. All you need to do is make sure the websites in the UIAlertController are correct, and this method will load anything.
    func openPage(action: UIAlertAction! = nil) {
        let url = URL(string:  "https://" + action.title!)!
        webView.load(URLRequest(url: url))
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        title = webView.title
    }
    
    // This delegate callback allows us to decide whether we want to allow navigation to happen or not every time something happens. We can check which part of the page started the navigation, we can see whether it was triggered by a link being clicked or a form being submitted, or, in our case, we can check the URL to see whether we like it.
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // First, we set the constant url to be equal to the URL of the navigation. This is just to make the code clearer.
        let url = navigationAction.request.url
        
        // Second, we use if let syntax to unwrap the value of the optional url.host. Remember I said that URL does a lot of work for you in parsing URLs properly? Well, here's a good example: this line says, "if there is a host for this URL, pull it out" – and by "host" it means "website domain" like apple.com. Note: we need to unwrap this carefully because not all URLs have hosts.
        if let host = url?.host {
            // Third, we loop through all sites in our safe list, placing the name of the site in the website variable.
            for website in websites {
                // Fourth, we use the contains() String method to see whether each safe website exists somewhere in the host name.
                if host .contains(website) {
                    // Fifth, if the website was found then we call the decision handler with a positive response - we want to allow loading.
                    decisionHandler(.allow)
                    // Sixth, if the website was found, after calling the decisionHandler we use the return statement. This means "exit the method now."
                    return
                }
            }
        }
        
        // Last, if there is no host set, or if we've gone through all the loop and found nothing, we call the decision handler with a negative response: cancel loading.
        decisionHandler(.cancel)
    }
    
    func websiteBlocked() {
        let ac = UIAlertController(title: "Website blocked", message: "You tried to visit a URL that isn't allowed.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: openPage))
        present(ac, animated: true)
    }
}


//
//  ViewController.swift
//  Selfie Share
//
//  Created by Timothy on 01/06/2023.
//

import UIKit
import MultipeerConnectivity

class ViewController: UICollectionViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, MCSessionDelegate, MCBrowserViewControllerDelegate {
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    // When a user connects or disconnects from our session, the method session(_:peer:didChangeState:) is called so you know what's changed – is someone connecting, are they now connected, or have they just disconnected? We're not going to be using this information in the project, but I do want to show you how it might be used by printing out some diagnostics. This is helpful for debugging, because it means you can look in Xcode's debug console to see these messages and know your code is working.
    // When this method is called, you'll be told what peer changed state, and what their new state is. There are only three possible session states: not connected, connecting, and connected. So, we can make our app print out useful information just by using switch/case and a bit of print():
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
            case .connected:
                print("Connected: \(peerID.displayName)")

            case .connecting:
                print("Connecting: \(peerID.displayName)")

            case .notConnected:
                print("Not Connected: \(peerID.displayName)")

            // While we could have made one of the other cases handle that using a regular default case, in this project none of them really make sense for whatever might occur in the future so I’ve added a dedicated @unknown default case to handle future cases.
            @unknown default:
                print("Unknown state received: \(peerID.displayName)")
            }
    }
    
    // Right now, when we add a picture to the collection view it is shown on our screen but doesn't go anywhere. We're going to add some code to the image picker's didFinishPickingMediaWithInfo method so that when an image is added it also gets sent out to peers.
    // Sending images across a multipeer connection is remarkably easy. In project 10 we used the function jpegData() to convert a UIImage object into a Data so it can be saved to disk, and here we’ll be using pngData() that does the same thing with the PNG image format. Once we have that, MCSession objects have a sendData() method that will ensure that data gets transmitted reliably to your peers.
    // Once the data arrives at each peer, the method session(_:didReceive:fromPeer:) will get called with that data, at which point we can create a UIImage from it and add it to our images array. There is one catch: when you receive data it might not be on the main thread, and you never manipulate user interfaces anywhere but the main thread, right? Right.
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // Take note of the call to async() to ensure we definitely only manipulate the user interface on the main thread!
        DispatchQueue.main.async { [weak self] in
            if let image = UIImage(data: data) {
                self?.images.insert(image, at: 0)
                self?.collectionView.reloadData()
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // no need for code here
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // no need for code here
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // no need for code here
    }
    
    var images = [UIImage]()
    
    var peerID = MCPeerID(displayName: UIDevice.current.name)
    var mcSession: MCSession?
    var mcAdvertiserAssistant: MCAdvertiserAssistant?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        title = "Selfie Share"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(importPicture))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showConnectionPrompt))
        
        // Most important of all is that all multipeer services on iOS must declare a service type, which is a 15-digit string that uniquely identify your service. Those 15 digits can contain only the letters A-Z, numbers and hyphens, and it's usually preferred to include your company in there somehow.
        // Apple's example is, "a text chat app made by ABC company could use the service type abc-txtchat"; for this project I'll be using hws-project25.
        // This service type is used by both MCAdvertiserAssistant and MCBrowserViewController to make sure your users only see other users of the same app. They both also want a reference to your MCSession instance so they can take care of connections for you.
        // We're going to start by initializing our MCSession so that we're able to make connections.
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession?.delegate = self
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageView", for: indexPath)
        
        if let imageView = cell.viewWithTag(1000) as? UIImageView {
            imageView.image = images[indexPath.item]
        }
        
        return cell
    }
    
    @objc func importPicture() {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else {
            return
        }
        
        dismiss(animated: true)
        
        images.insert(image, at: 0)
        collectionView.reloadData()
        
        // Send image data to peers.
        // 1. Check if we have an active session we can use.
        guard let mcSession else {
            return
        }
        
        // 2. Check if there are any peers to send to.
        if mcSession.connectedPeers.count > 0 {
            // 3. Convert the new image to a Data object.
            if let imageData = image.pngData() {
                // 4. Send it to all peers, ensuring it gets delivered.
                do {
                    try mcSession.send(imageData, toPeers: mcSession.connectedPeers, with: .reliable)
                } catch {
                    // 5. Show an error message if there's a problem.
                    let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    present(ac, animated: true)
                }
            }
        }
    }
    
    @objc func showConnectionPrompt() {
        let ac = UIAlertController(title: "Connect to others", message: nil, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Host a session", style: .default, handler: startHosting))
        ac.addAction(UIAlertAction(title: "Join a session", style: .default, handler: joinSession))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }

    func startHosting(action: UIAlertAction) {
        guard let mcSession = mcSession else {
            return
        }
        
        mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "Selfie-Share", discoveryInfo: nil, session: mcSession)
        mcAdvertiserAssistant?.start()
    }
    
    func joinSession(action: UIAlertAction) {
        guard let mcSession = mcSession else {
            return
        }
        
        let mcBrowser = MCBrowserViewController(serviceType: "Selfie-Share", session: mcSession)
        mcBrowser.delegate = self
        present(mcBrowser, animated: true)
    }
}


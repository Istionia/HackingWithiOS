//
//  ViewController.swift
//  StormViewer
//
//  Created by Timothy on 18/12/2022.
//

import UIKit

class ViewController: UITableViewController {
    var pictures = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // Declares a constant called fm and assigns it the value returned by FileManager.default. This is a data type that lets us work with the filesystem, and in our case we'll be using it to look for files.
        title = "Storm Viewer"
        let fm = FileManager.default
        // Declares a constant called path that is set to the resource path of our app's bundle. Remember, a bundle is a directory containing our compiled program and all our assets. So, this line says, "tell me where I can find all those images I added to my app."
        let path = Bundle.main.resourcePath!
        // Declares a third constant called items that is set to the contents of the directory at a path. Which path? Well, the one that was returned by the line before. As you can see, Apple's long method names really does make their code quite self-descriptive! The items constant will be an array of strings containing filenames.
        var items = try! fm.contentsOfDirectory(atPath: path)
        
        // Starts a loop that will execute once for every item we found in the app bundle. Remember: the line has an opening brace at the end, signaling the start of a new block of code, and there's a matching closing brace four lines beneath. Everything inside those braces will be executed each time the loop goes around.
        for item in items.sorted() {
            // First line inside our loop. By this point, we'll have the first filename ready to work with, and it'll be called item. To decide whether it's one we care about or not, we use the hasPrefix() method: it takes one parameter (the prefix to search for) and returns either true or false. That "if" at the start means this line is a conditional statement: if the item has the prefix "nssl", then… that's right, another opening brace to mark another new code block. This time, the code will be executed only if hasPrefix() returned true.
            if item.hasPrefix("nssl") {
                // this is a picture to load!
                pictures.append(item)
            }
            
            // bar button item that recommends the app to other people
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareTapped))
        }
        
        print(pictures)
        
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    // The override keyword means the method has been defined already, and we want to override the existing behavior with this new behavior. If you didn't override it, then the previously defined method would execute, and in this instance it would say there are no rows.
    // The func keyword starts a new function or a new method; Swift uses the same keyword for both. Technically speaking a method is a function that appears inside a class, just like our ViewController, but otherwise there’s no difference.
    // The method’s name comes next: tableView. That doesn't sound very useful, but the way Apple defines methods is to ensure that the information that gets passed into them – the parameters – are named usefully, and in this case the very first thing that gets passed in is the table view that triggered the code. A table view, as you might have gathered, is the scrolling thing that will contain all our image names, and is a core component in iOS.
    // As promised, the next thing to come is tableView: UITableView, which is the table view that triggered the code. But this contains two pieces of information at once: tableView is the name that we can use to reference the table view inside the method, and UITableView is the data type – the bit that describes what it is.
    // The most important part of the method comes next: numberOfRowsInSection section: Int. This describes what the method actually does. We know it involves a table view because that's the name of the method, but the numberOfRowsInSection part is the actual action: this code will be triggered when iOS wants to know how many rows are in the table view. The section part is there because table views can be split into sections, like the way the Contacts app separates names by first letter. We only have one section, so we can ignore this number. The Int part means “this will be an integer,” which means a whole number like 3, 30, or 35678 number.”
    // Finally, -> Int means “this method must return an integer”, which ought to be the number of rows to show in the table.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // We wrote only one line of code in the method, which was return pictures.count. That means “send back the number of pictures in our array,” so we’re asking that there be as many table rows as there are pictures.
        return pictures.count
    }
    
    // Did you notice that _ in there? I hope you can remember that means the first parameter isn’t passed in using a name when called externally – this is a remnant of Objective-C, where the name of the first parameter was usually built right into the method name.
    // In this instance, the method is called tableView() because its first parameter is the table view that you’re working with. It wouldn’t make much sense to write tableView(tableView: someTableView), so using the underscore means you would write tableView(someTableView) instead.
    
    // First, override func tableView(_ tableView: UITableView is identical to the previous method: the method name is just tableView(), and it will pass in a table view as its first parameter. The _ means it doesn’t need to have a name sent externally, because it’s the same as the method name.
    
    // Second, cellForRowAt indexPath: IndexPath is the important part of the method name. The method is called cellForRowAt, and will be called when you need to provide a row. The row to show is specified in the parameter: indexPath, which is of type IndexPath. This is a data type that contains both a section number and a row number. We only have one section, so we can ignore that and just use the row number.

    // Third, -> UITableViewCell means this method must return a table view cell. If you remember, we created one inside Interface Builder and gave it the identifier “Picture”, so we want to use that.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Picture", for: indexPath)
        cell.textLabel?.text = pictures[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 1: try loading the "Detail" view controller and typecasting it to be DetailViewController
        if let vc = storyboard?.instantiateViewController(withIdentifier: "Detail") as? DetailViewController {
            // 2: success! Set its selectedImage property
            vc.selectedImage = pictures[indexPath.row]
            
            // set values for selectedImageNumber
            vc.selectedImageNumber = indexPath.row + 1
            
            // set values for totalNumberOfImages
            vc.totalNumberOfImages = pictures.count
            
            // 3: now push it onto the navigation controller
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @objc func shareTapped() {
        let vc = UIActivityViewController(activityItems: [], applicationActivities: [])
        vc.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(vc, animated: true)
    }
}


//
//  ViewController.swift
//  Project6b
//
//  Created by Timothy on 15/05/2023.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
            let label1 = UILabel()
            label1.translatesAutoresizingMaskIntoConstraints = false
            label1.backgroundColor = UIColor.red
            label1.text = "THESE"
            label1.sizeToFit()

            let label2 = UILabel()
            label2.translatesAutoresizingMaskIntoConstraints = false
            label2.backgroundColor = UIColor.cyan
            label2.text = "ARE"
            label2.sizeToFit()

            let label3 = UILabel()
            label3.translatesAutoresizingMaskIntoConstraints = false
            label3.backgroundColor = UIColor.yellow
            label3.text = "SOME"
            label3.sizeToFit()

            let label4 = UILabel()
            label4.translatesAutoresizingMaskIntoConstraints = false
            label4.backgroundColor = UIColor.green
            label4.text = "AWESOME"
            label4.sizeToFit()

            let label5 = UILabel()
            label5.translatesAutoresizingMaskIntoConstraints = false
            label5.backgroundColor = UIColor.orange
            label5.text = "LABELS"
            label5.sizeToFit()

            view.addSubview(label1)
            view.addSubview(label2)
            view.addSubview(label3)
            view.addSubview(label4)
            view.addSubview(label5)
        
        let viewsDictionary = ["label1": label1, "label2": label2, "label3": label3, "label4": label4, "label5": label5]
        
        var previous: UILabel?
        
        for label in [label1, label2, label3, label4, label5] {
            if #available(iOS 11, *) {
                label.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
                label.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
            } else {
                label.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
                label.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            }
            
            label.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.2, constant: 10).isActive = true
            
            if let previous = previous {
                // we have a previous label – create a height constraint
                label.topAnchor.constraint(equalTo: previous.bottomAnchor, constant: 10)
            } else {
                // this is the first label
                if #available(iOS 11, *) {
                    label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
                } else {
                    label.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
                }
            }
            
            // set the previous label to be the current one, for the next loop iteration
            previous = label
        }
        // Let's eliminate the easy stuff, then focus on what remains.

            // view.addConstraints(): this adds an array of constraints to our view controller's view. This array is used rather than a single constraint because VFL can generate multiple constraints at a time.
            // NSLayoutConstraint.constraints(withVisualFormat:) is the Auto Layout method that converts VFL into an array of constraints. It accepts lots of parameters, but the important ones are the first and last.
            // We pass [] (an empty array) for the options parameter and nil for the metrics parameter. You can use these options to customize the meaning of the VFL, but for now we don't care.
        // That's the easy stuff. So, let's look at the Visual Format Language itself: "H:|[label1]|". As you can see it's a string, and that string describes how we want the layout to look. That VFL gets converted into Auto Layout constraints, then added to the view.

        // The H: parts means that we're defining a horizontal layout; we'll do a vertical layout soon. The pipe symbol, |, means "the edge of the view." We're adding these constraints to the main view inside our view controller, so this effectively means "the edge of the view controller." Finally, we have [label1], which is a visual way of saying "put label1 here". Imagine the brackets, [ and ], are the edges of the view.

        // So, "H:|[label1]|" means "horizontally, I want my label1 to go edge to edge in my view." But there's a hiccup: what is "label1"? Sure, we know what it is because it's the name of our variable, but variable names are just things for humans to read and write – the variable names aren't actually saved and used when the program runs.

        // This is where our viewsDictionary dictionary comes in: we used strings for the key and UILabels for the value, then set "label1" to be our label. This dictionary gets passed in along with the VFL, and gets used by iOS to look up the names from the VFL. So when it sees [label1], it looks in our dictionary for the "label1" key and uses its value to generate the Auto Layout constraints.

        // That's the entire VFL line explained: each of our labels should stretch edge-to-edge in our view. If you run the program now, that's sort of what you'll see, although it highlights our second problem: we don't have a vertical layout in place, so although all the labels sit edge-to-edge in the view, they all overlap.
    }


}


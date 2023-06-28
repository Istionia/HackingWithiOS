//
//  ViewController.swift
//  NamestoFaces
//
//  Created by Timothy on 20/05/2023.
//

import UIKit

// The first of those protocols is useful, telling us when the user either selected a picture or cancelled the picker. The second, UINavigationControllerDelegate, really is quite pointless here, so don't worry about it beyond just modifying your class declaration to include the protocol.
// When you conform to the UIImagePickerControllerDelegate protocol, you don't need to add any methods because both are optional. But they aren't really – they are marked optional for whatever reason, but your code isn't much good unless you implement at least one of them!
class ViewController: UICollectionViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    var people = [Person]()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewPerson))
    }

    // This must return an integer, and tells the collection view how many items you want to show in its grid. I've returned 10 from this method, but soon we'll switch to using an array.
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return people.count
    }
    
    // This must return an object of type UICollectionViewCell. We already designed a prototype in Interface Builder, and configured the PersonCell class for it, so we need to create and return one of these.
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Person", for: indexPath) as? PersonCell else {
                fatalError("Unable to dequeue PersonCell.")
            }

            // used indexPath.item rather than indexPath.row, because collection views don’t really think in terms of rows.
            let person = people[indexPath.item]

            cell.name.text = person.name

            let path = getDocumentsDirectory().appendingPathComponent(person.image)
            cell.imageView.image = UIImage(contentsOfFile: path.path)
        
            // snuck in a new UIColor initializer: UIColor(white:alpha:); this is useful when you only want grayscale colors.
            cell.imageView.layer.borderColor = UIColor(white: 0, alpha: 0.3).cgColor
            cell.imageView.layer.borderWidth = 2
            // sets the cornerRadius property, which rounds the corners of a CALayer – or in our case the UIView being drawn by the CALayer.
            cell.imageView.layer.cornerRadius = 3
            cell.layer.cornerRadius = 7

            return cell
    }
    
    // The whole method is being called from Objective-C code using #selector, so we need to use the @objc attribute. This is the last time I’ll be repeating this, but hopefully you’re mentally always expecting #selector to be paired with @objc.
    @objc func addNewPerson() {
        let picker = UIImagePickerController()
        // // We set the allowsEditing property to be true, which allows the user to crop the picture they select.
        picker.allowsEditing = true
        // When you set self as the delegate, you'll need to conform not only to the UIImagePickerControllerDelegate protocol, but also the UINavigationControllerDelegate protocol.
        picker.delegate = self
        present(picker, animated: true)
    }
    
    // As you can see I’ve used guard to pull out and typecast the image from the image picker, because if that fails we want to exit the method immediately. We then create an UUID object, and use its uuidString property to extract the unique identifier as a string data type.
    // The code then creates a new constant, imagePath, which takes the URL result of getDocumentsDirectory() and calls a new method on it: appendingPathComponent(). This is used when working with file paths, and adds one string (imageName in our case) to a path, including whatever path separator is used on the platform.
    // Now that we have a UIImage containing an image and a path where we want to save it, we need to convert the UIImage to a Data object so it can be saved. To do that, we use the jpegData() method, which takes one parameter: a quality value between 0 and 1, where 1 is “maximum quality”.
    // Once we have a Data object containing our JPEG data, we just need to unwrap it safely then write it to the file name we made earlier. That's done using the write(to:) method, which takes a filename as its parameter.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        
        let imageName = UUID().uuidString
            let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)

            if let jpegData = image.jpegData(compressionQuality: 0.8) {
                try? jpegData.write(to: imagePath)
            }
        
            let person = Person(name: "Unknown", image: imageName)
            people.append(person)
            collectionView.reloadData()

            dismiss(animated: true)
    }
    
    // The first parameter of FileManager.default.urls asks for the documents directory, and its second parameter adds that we want the path to be relative to the user's home directory. This returns an array that nearly always contains only one thing: the user's documents directory. So, we pull out the first element and return it.
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let person = people[indexPath.item]
        
        let ac = UIAlertController(title: "Rename person", message: nil, preferredStyle: .alert)
        ac.addTextField()
        
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        ac.addAction(UIAlertAction(title: "OK", style: .default) { [weak self, weak ac] _ in
            guard let newName = ac?.textFields?[0].text else { return }
            person.name = newName
            
            self?.collectionView.reloadData()
        })
        
        present(ac, animated: true)
    }
}


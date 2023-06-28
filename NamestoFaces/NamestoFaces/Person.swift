//
//  Person.swift
//  NamestoFaces
//
//  Created by Timothy on 20/05/2023.
//

import UIKit

class Person: NSObject {
    var name: String
    var image: String
    
    init(name: String, image: String) {
        self.name = name
        self.image = image
    }
}

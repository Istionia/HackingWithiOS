//
//  Capital.swift
//  Capital Cities
//
//  Created by Timothy on 26/05/2023.
//

import MapKit
import UIKit

class Capital: NSObject {
    var title: String?
    var coordinate: CLLocationCoordinate2D
    var info: String
    
    init(title: String? = nil, coordinate: CLLocationCoordinate2D, info: String) {
        self.title = title
        self.coordinate = coordinate
        self.info = info
    }
}

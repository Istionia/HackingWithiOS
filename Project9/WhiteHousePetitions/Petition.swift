//
//  Petition.swift
//  WhiteHousePetitions
//
//  Created by Timothy on 17/05/2023.
//

import Foundation

struct Petition: Codable {
    var title: String
    var body: String
    var signatureCount: Int
}

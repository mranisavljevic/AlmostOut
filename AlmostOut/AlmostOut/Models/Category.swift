//
//  Category.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/11/25.
//

import Foundation

struct ItemCategory: Codable, Equatable {
    let name: String
    let isCustom: Bool
    let scope: CategoryScope
    
    enum CategoryScope: String, Codable {
        case global, user, list
    }
}

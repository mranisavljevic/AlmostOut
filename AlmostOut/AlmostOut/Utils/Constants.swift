//
//  Constants.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/11/25.
//

import Foundation

struct FirebaseConstants {
    static let usersCollection = "users"
    static let listsCollection = "lists"
    static let itemsSubcollection = "items"
    static let categoriesCollection = "categories"
    static let invitationsCollection = "invitations"
    static let templatesSubcollection = "templates"
    
    static let defaultCategories = [
        "produce", "dairy", "meat", "bakery", "frozen",
        "pantry", "beverages", "snacks", "household",
        "personal care", "pharmacy", "other"
    ]
}

struct StorageConstants {
    static let shoppingListsFolder = "shopping-lists"
    static let imagesFolder = "images"
    static let thumbnailSuffix = "_thumb"
    static let maxImageSize: Int64 = 5 * 1024 * 1024 // 5MB
    static let maxImagesPerItem = 3
}

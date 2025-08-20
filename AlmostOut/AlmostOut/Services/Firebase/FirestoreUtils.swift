//
//  FirestoreError.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/12/25.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Foundation

extension Notification.Name {
    static let openList = Notification.Name("openList")
    static let itemAdded = Notification.Name("itemAdded")
    static let itemCompleted = Notification.Name("itemCompleted")
}

// MARK: - Firebase Emulator Configuration (for Development)

extension Firestore {
    static func configureForEmulator() {
        let firestore = Firestore.firestore()
        let settings = firestore.settings
        settings.host = "localhost:8080"
        settings.isPersistenceEnabled = false
        settings.isSSLEnabled = false
        firestore.settings = settings
    }
}

extension Auth {
    static func configureForEmulator() {
        Auth.auth().useEmulator(withHost: "localhost", port: 9099)
    }
}

extension Storage {
    static func configureForEmulator() {
        Storage.storage().useEmulator(withHost: "localhost", port: 9199)
    }
}

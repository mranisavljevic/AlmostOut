//
//  Untitled.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/11/25.
//

import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    let uid: String
    let email: String
    let displayName: String
    let profileImageUrl: String?
    let createdAt: Date
    let updatedAt: Date
    let preferences: UserPreferences
    let fcmTokens: [String]
    
    struct UserPreferences: Codable {
        let pushNotifications: Bool
        let locationNotifications: Bool
        let emailDigest: Bool
        
        init(pushNotifications: Bool = true, locationNotifications: Bool = true, emailDigest: Bool = false) {
            self.pushNotifications = pushNotifications
            self.locationNotifications = locationNotifications
            self.emailDigest = emailDigest
        }
    }
}

//
//  FirebaseNotificationService.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/12/25.
//

import CoreLocation
import FirebaseAuth
import FirebaseMessaging
import FirebaseFirestore
import Foundation
import UserNotifications

class FirebaseNotificationService: NotificationServiceProtocol {
    func requestPermission() async throws -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        
        if settings.authorizationStatus == .notDetermined {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        }
        
        return settings.authorizationStatus == .authorized
    }
    
    func updateFCMToken() async throws {
        guard let token = try? await Messaging.messaging().token() else {
            throw NotificationError.tokenRetrievalFailed
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NotificationError.userNotAuthenticated
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        try await userRef.updateData([
            "fcmTokens": FieldValue.arrayUnion([token])
        ])
    }
    
    func scheduleLocationReminder(for items: [ListItem], at coordinate: CLLocationCoordinate2D) throws {
        // Implementation for location-based notifications
        // This would use Core Location to set up geofences
    }
}

enum NotificationError: Error, LocalizedError {
    case tokenRetrievalFailed
    case userNotAuthenticated
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .tokenRetrievalFailed:
            return "Failed to retrieve FCM token"
        case .userNotAuthenticated:
            return "User not authenticated"
        case .permissionDenied:
            return "Notification permission denied"
        }
    }
}

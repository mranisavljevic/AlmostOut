//
//  AppDelegate.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/12/25.
//

import Firebase
import FirebaseAppCheck
import FirebaseAuth
import Foundation

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        /** We can add this AppAttest app check later
        let providerFactory = AlmostOutAppCheckProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        **/
        
        // Configure Firebase
        FirebaseApp.configure()
        
        // Configure Firestore settings
        let db = Firestore.firestore()
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: FirestoreCacheSizeUnlimited as NSNumber)
        db.settings = settings
        
        // Configure push notifications
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        
        // Request notification permissions
        requestNotificationPermissions()
        
        // Register for remote notifications
        application.registerForRemoteNotifications()
        
        return true
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permissions granted")
            } else if let error = error {
                print("Notification permissions denied: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Push Notification Handlers
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    // Handle notifications when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .badge, .sound])
    }
    
    // Handle notification taps
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle deep linking based on notification data
        if let listId = userInfo["listId"] as? String {
            NotificationCenter.default.post(name: .openList, object: listId)
        }
        
        completionHandler()
    }
    
    // MARK: - Firebase Messaging Delegate
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        print("FCM registration token: \(fcmToken)")
        
        // Update user's FCM token in Firestore
        updateFCMToken(fcmToken)
    }
    
    private func updateFCMToken(_ token: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        userRef.updateData([
            "fcmTokens": FieldValue.arrayUnion([token])
        ]) { error in
            if let error = error {
                print("Error updating FCM token: \(error.localizedDescription)")
            } else {
                print("FCM token updated successfully")
            }
        }
    }
}

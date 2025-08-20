//
//  AlmostOutApp.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/11/25.
//

import SwiftUI

@main
struct AlmostOutApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
        }
    }
}

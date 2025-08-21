//
//  ContentView.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/11/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                AuthenticationView()
            }
        }
        .animation(.easeInOut, value: authViewModel.isAuthenticated)
    }
}

#Preview("Content View") {
    ContentView()
        .environmentObject(AuthViewModel(authService: MockAuthService()))
}

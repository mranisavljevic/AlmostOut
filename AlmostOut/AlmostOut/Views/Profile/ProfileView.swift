//
//  ProfileView.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/21/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingSignOutConfirmation = false
    
    var body: some View {
        NavigationView {
            List {
                if let user = authViewModel.currentUser {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(user.displayName)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Section("Preferences") {
                        Toggle("Push Notifications", isOn: .constant(user.preferences.pushNotifications))
                        Toggle("Location Reminders", isOn: .constant(user.preferences.locationNotifications))
                        Toggle("Email Digest", isOn: .constant(user.preferences.emailDigest))
                    }
                }
                
                Section {
                    Button("Sign Out") {
                        showingSignOutConfirmation = true
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Profile")
        }
        .confirmationDialog("Sign Out", isPresented: $showingSignOutConfirmation, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                authViewModel.signOut()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

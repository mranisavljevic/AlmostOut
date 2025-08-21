//
//  AuthenticationView.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/21/25.
//

import SwiftUI

struct AuthenticationView: View {
    @State private var isSigningIn = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // App Logo/Title
                VStack(spacing: 8) {
                    Image(systemName: "list.clipboard.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("AlmostOut")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Never forget what you're running low on")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 40)
                
                // Auth Form
                if isSigningIn {
                    SignInView()
                } else {
                    SignUpView()
                }
                
                // Toggle Sign In/Up
                Button {
                    withAnimation {
                        isSigningIn.toggle()
                    }
                } label: {
                    Text(isSigningIn ? "Don't have an account? Sign up" : "Already have an account? Sign in")
                        .font(.footnote)
                        .foregroundColor(.blue)
                }
                .padding(.top)
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}

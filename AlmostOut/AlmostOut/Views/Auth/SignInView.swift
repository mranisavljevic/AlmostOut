//
//  SignInView.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/21/25.
//

import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 16) {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.emailAddress)
                .autocapitalization(.none)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.password)
            
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button {
                Task {
                    await authViewModel.signIn(email: email, password: password)
                }
            } label: {
                if authViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Sign In")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(authViewModel.isLoading || email.isEmpty || password.isEmpty)
        }
    }
}

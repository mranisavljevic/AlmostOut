//
//  MockAuthService.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/11/25.
//

import XCTest
import Combine

class MockAuthService: AuthServiceProtocol {
    @Published var currentUser: User?
    private let authStateSubject = CurrentValueSubject<User?, Never>(nil)
    
    var isAuthenticated: Bool {
        currentUser != nil
    }
    
    var authStatePublisher: AnyPublisher<User?, Never> {
        authStateSubject.eraseToAnyPublisher()
    }
    
    var shouldFailSignIn = false
    var shouldFailSignUp = false
    
    func signIn(email: String, password: String) async throws -> User {
        if shouldFailSignIn {
            throw NSError(domain: "MockError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid credentials"])
        }
        
        let user = User(
            uid: "test-uid",
            email: email,
            displayName: "Test User",
            profileImageUrl: nil,
            createdAt: Date(),
            updatedAt: Date(),
            preferences: User.UserPreferences(),
            fcmTokens: []
        )
        
        currentUser = user
        authStateSubject.send(user)
        return user
    }
    
    func signUp(email: String, password: String, displayName: String) async throws -> User {
        if shouldFailSignUp {
            throw NSError(domain: "MockError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Email already exists"])
        }
        
        let user = User(
            uid: "test-uid",
            email: email,
            displayName: displayName,
            profileImageUrl: nil,
            createdAt: Date(),
            updatedAt: Date(),
            preferences: User.UserPreferences(),
            fcmTokens: []
        )
        
        currentUser = user
        authStateSubject.send(user)
        return user
    }
    
    func signOut() throws {
        currentUser = nil
        authStateSubject.send(nil)
    }
    
    func deleteAccount() async throws {
        currentUser = nil
        authStateSubject.send(nil)
    }
}

//
//  FirebaseAuthService.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/11/25.
//

import Combine
import Firebase
import FirebaseAuth
import FirebaseFirestore

class FirebaseAuthService: AuthServiceProtocol {
    @Published private(set) var currentUser: User?
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    var isAuthenticated: Bool {
        currentUser != nil
    }
    
    var authStatePublisher: AnyPublisher<User?, Never> {
        $currentUser.eraseToAnyPublisher()
    }
    
    init() {
        setupAuthListener()
    }
    
    private func setupAuthListener() {
        _ = auth.addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor in
                if let firebaseUser = firebaseUser {
                    do {
                        let user = try await self?.fetchOrCreateUser(firebaseUser)
                        self?.currentUser = user
                    } catch {
                        print("Error fetching user: \(error)")
                        self?.currentUser = nil
                    }
                } else {
                    self?.currentUser = nil
                }
            }
        }
    }
    
    func signIn(email: String, password: String) async throws -> User {
        let result = try await auth.signIn(withEmail: email, password: password)
        return try await fetchOrCreateUser(result.user)
    }
    
    func signUp(email: String, password: String, displayName: String) async throws -> User {
        let result = try await auth.createUser(withEmail: email, password: password)
        
        // Update display name
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        try await changeRequest.commitChanges()
        
        return try await fetchOrCreateUser(result.user)
    }
    
    func signOut() throws {
        try auth.signOut()
    }
    
    func deleteAccount() async throws {
        guard let user = auth.currentUser else { return }
        try await user.delete()
    }
    
    private func fetchOrCreateUser(_ firebaseUser: FirebaseAuth.User) async throws -> User {
        let userRef = db.collection(FirebaseConstants.usersCollection).document(firebaseUser.uid)
        
        do {
            let document = try await userRef.getDocument()
            
            if document.exists {
                return try document.data(as: User.self)
            } else {
                // Create new user document
                let newUser = User(
                    uid: firebaseUser.uid,
                    email: firebaseUser.email ?? "",
                    displayName: firebaseUser.displayName ?? "",
                    profileImageUrl: firebaseUser.photoURL?.absoluteString,
                    createdAt: Date(),
                    updatedAt: Date(),
                    preferences: User.UserPreferences(),
                    fcmTokens: []
                )
                
                try userRef.setData(from: newUser)
                return newUser
            }
        } catch {
            throw error
        }
    }
}

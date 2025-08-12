//
//  AuthViewModelTests.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/11/25.
//

import XCTest
@testable import AlmostOut

@MainActor
final class AuthViewModelTests: XCTestCase {
    var viewModel: AuthViewModel!
    var mockAuthService: MockAuthService!
    
    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthService()
        viewModel = AuthViewModel(authService: mockAuthService)
    }
    
    override func tearDown() {
        viewModel = nil
        mockAuthService = nil
        super.tearDown()
    }
    
    func testSuccessfulSignIn() async {
        // Given
        let email = "test@example.com"
        let password = "password123"
        
        // When
        await viewModel.signIn(email: email, password: password)
        
        // Then
        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertNotNil(viewModel.currentUser)
        XCTAssertEqual(viewModel.currentUser?.email, email)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testFailedSignIn() async {
        // Given
        mockAuthService.shouldFailSignIn = true
        
        // When
        await viewModel.signIn(email: "test@example.com", password: "wrong")
        
        // Then
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertNil(viewModel.currentUser)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "Invalid credentials")
    }
    
    func testSignOut() {
        // Given
        mockAuthService.currentUser = User(
            uid: "test-uid",
            email: "test@example.com",
            displayName: "Test User",
            profileImageUrl: nil,
            createdAt: Date(),
            updatedAt: Date(),
            preferences: User.UserPreferences(),
            fcmTokens: []
        )
        
        // When
        viewModel.signOut()
        
        // Then
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertNil(viewModel.currentUser)
    }
}

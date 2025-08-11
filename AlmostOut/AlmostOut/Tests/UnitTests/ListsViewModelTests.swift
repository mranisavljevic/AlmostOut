//
//  ListsViewModelTests.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/11/25.
//

import XCTest

class ListsViewModelTests: XCTestCase {
    var viewModel: ListsViewModel!
    var mockDatabaseService: MockDatabaseService!
    var mockAuthService: MockAuthService!
    
    override func setUp() {
        super.setUp()
        mockDatabaseService = MockDatabaseService()
        mockAuthService = MockAuthService()
        viewModel = ListsViewModel(
            databaseService: mockDatabaseService,
            authService: mockAuthService
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockDatabaseService = nil
        mockAuthService = nil
        super.tearDown()
    }
    
    func testListsLoadWhenUserSignsIn() async {
        // Given
        let mockList = ShoppingList(
            id: "list1",
            name: "Groceries",
            description: "Weekly groceries",
            createdBy: "test-uid",
            createdAt: Date(),
            updatedAt: Date(),
            members: [:],
            isArchived: false,
            totalItems: 5,
            completedItems: 2
        )
        mockDatabaseService.mockLists = [mockList]
        
        // When
        let user = User(
            uid: "test-uid",
            email: "test@example.com",
            displayName: "Test User",
            profileImageUrl: nil,
            createdAt: Date(),
            updatedAt: Date(),
            preferences: User.UserPreferences(),
            fcmTokens: []
        )
        mockAuthService.currentUser = user
        
        // Give some time for the publisher to emit
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        XCTAssertEqual(viewModel.lists.count, 1)
        XCTAssertEqual(viewModel.lists.first?.name, "Groceries")
    }
    
    func testCreateList() async {
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
        await viewModel.createList(name: "New List", description: "Test description")
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(mockDatabaseService.mockLists.count, 1)
        XCTAssertEqual(mockDatabaseService.mockLists.first?.name, "New List")
    }
    
    func testCreateListFailure() async {
        // Given
        mockDatabaseService.shouldFailOperations = true
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
        await viewModel.createList(name: "New List")
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "Database error")
    }
}

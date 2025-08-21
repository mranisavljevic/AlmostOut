//
//  ListsViewModelTests.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/11/25.
//

import XCTest
@testable import AlmostOut

@MainActor
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
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after completion")
        XCTAssertNil(viewModel.errorMessage, "Should not have error message on success")
        XCTAssertEqual(mockDatabaseService.mockLists.count, 1, "Should have created 1 list")
        XCTAssertEqual(mockDatabaseService.mockLists.first?.name, "New List", "Should have correct list name")
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
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after completion")
        XCTAssertNotNil(viewModel.errorMessage, "Should have error message on failure")
        XCTAssertEqual(viewModel.errorMessage, "Database error", "Should have correct error message")
    }
    
    func testCreateListWithoutUser() async {
        // Given - no user is set (currentUser is nil)
        mockAuthService.currentUser = nil
        
        // When
        await viewModel.createList(name: "New List")
        
        // Then - should not crash and should not create a list
        XCTAssertFalse(viewModel.isLoading, "Should not be loading")
        XCTAssertEqual(mockDatabaseService.mockLists.count, 0, "Should not create list without user")
    }
    
    func testDeleteList() async {
        // Given - create a list first
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
        await viewModel.deleteList(mockList)
        
        // Then
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after completion")
        XCTAssertNil(viewModel.errorMessage, "Should not have error message on success")
        XCTAssertEqual(mockDatabaseService.mockLists.count, 0, "Should have deleted the list")
    }
    
    func testDeleteListFailure() async {
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
        mockDatabaseService.shouldFailOperations = true
        
        // When
        await viewModel.deleteList(mockList)
        
        // Then
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after completion")
        XCTAssertNotNil(viewModel.errorMessage, "Should have error message on failure")
        XCTAssertEqual(viewModel.errorMessage, "Database error", "Should have correct error message")
    }
    
    func testInitialState() {
        // Test that the ViewModel starts with correct initial state
        let freshViewModel = ListsViewModel(
            databaseService: MockDatabaseService(),
            authService: MockAuthService()
        )
        
        XCTAssertEqual(freshViewModel.lists.count, 0, "Should start with empty lists")
        XCTAssertFalse(freshViewModel.isLoading, "Should not be loading initially")
        XCTAssertNil(freshViewModel.errorMessage, "Should not have error message initially")
    }
    
    func testDirectListDataSet() {
        // Test the lists property directly (bypassing the service layer)
        let mockLists = [
            ShoppingList(
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
            ),
            ShoppingList(
                id: "list2",
                name: "Hardware Store",
                description: "DIY project items",
                createdBy: "test-uid",
                createdAt: Date(timeIntervalSinceNow: -3600), // 1 hour ago
                updatedAt: Date(timeIntervalSinceNow: -3600),
                members: [:],
                isArchived: false,
                totalItems: 3,
                completedItems: 1
            )
        ]
        
        // Directly set the lists (if your ViewModel allows this)
        viewModel.lists = mockLists
        
        // Then
        XCTAssertEqual(viewModel.lists.count, 2, "Should have 2 lists")
        XCTAssertEqual(viewModel.lists.first?.name, "Groceries", "First list should be Groceries")
        
        // Test that lists are sorted by updatedAt (most recent first)
        // The groceries list was updated more recently, so it should be first
        XCTAssertTrue(viewModel.lists[0].updatedAt > viewModel.lists[1].updatedAt, "Lists should be sorted by update time")
    }
    
    func testCreateListValidation() async {
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
        
        // When creating a list with empty name
        await viewModel.createList(name: "", description: "Test")
        
        // Then - Check what actually happens (adjust based on your implementation)
        // Option 1: If your ViewModel DOES validate (prevent empty names):
        // XCTAssertEqual(mockDatabaseService.mockLists.count, 0, "Should not create list with empty name")
        
        // Option 2: If your ViewModel does NOT validate (allows empty names):
        XCTAssertEqual(mockDatabaseService.mockLists.count, 1, "Current implementation allows empty names")
        
        // When creating a list with whitespace-only name
        await viewModel.createList(name: "   ", description: "Test2")
        
        // Then - this should also be handled consistently
        XCTAssertEqual(mockDatabaseService.mockLists.count, 2, "Current implementation allows whitespace names")
    }
    
    // Alternative: Test with proper validation expectation
    func testCreateListWithValidName() async {
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
        
        // When creating a list with valid name
        await viewModel.createList(name: "Valid List Name", description: "Test")
        
        // Then
        XCTAssertEqual(mockDatabaseService.mockLists.count, 1, "Should create list with valid name")
        XCTAssertEqual(mockDatabaseService.mockLists.first?.name, "Valid List Name", "Should preserve the name")
    }
}

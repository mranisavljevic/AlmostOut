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
        
        // Test new array-based structure
        XCTAssertTrue(mockDatabaseService.mockLists.first?.memberIds.contains("test-uid") ?? false, "Should contain user in memberIds")
        XCTAssertEqual(mockDatabaseService.mockLists.first?.memberDetails["test-uid"]?.role, .owner, "User should be owner")
        XCTAssertEqual(mockDatabaseService.mockLists.first?.memberDetails["test-uid"]?.displayName, "Test User", "Should have correct display name")
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
        XCTAssertEqual(mockDatabaseService.mockLists.count, 1, "Current implementation allows empty names")
        
        // When creating a list with whitespace-only name
        await viewModel.createList(name: "   ", description: "Test2")
        
        // Then - this should also be handled consistently
        XCTAssertEqual(mockDatabaseService.mockLists.count, 2, "Current implementation allows whitespace names")
    }
    
    func testDirectListDataSet() {
        // Test the lists property directly with new structure
        let mockLists = [
            ShoppingList(
                id: "list1",
                name: "Groceries",
                description: "Weekly groceries",
                createdBy: "test-uid",
                createdAt: Date(),
                updatedAt: Date(),
                memberIds: ["test-uid", "other-user"],
                memberDetails: [
                    "test-uid": ShoppingList.ListMember(
                        role: .owner,
                        joinedAt: Date(),
                        displayName: "Test User"
                    ),
                    "other-user": ShoppingList.ListMember(
                        role: .editor,
                        joinedAt: Date(),
                        displayName: "Other User"
                    )
                ],
                isArchived: false,
                totalItems: 5,
                completedItems: 2
            ),
            ShoppingList(
                id: "list2",
                name: "Hardware Store",
                description: "DIY project items",
                createdBy: "test-uid",
                createdAt: Date(timeIntervalSinceNow: -3600),
                updatedAt: Date(timeIntervalSinceNow: -3600),
                memberIds: ["test-uid"],
                memberDetails: [
                    "test-uid": ShoppingList.ListMember(
                        role: .owner,
                        joinedAt: Date(),
                        displayName: "Test User"
                    )
                ],
                isArchived: false,
                totalItems: 3,
                completedItems: 1
            )
        ]
        
        // Set the lists directly
        viewModel.lists = mockLists
        
        // Test basic functionality
        XCTAssertEqual(viewModel.lists.count, 2, "Should have 2 lists")
        XCTAssertEqual(viewModel.lists.first?.name, "Groceries", "First list should be Groceries")
        
        // Test new helper methods
        XCTAssertTrue(viewModel.lists[0].isUserMember("test-uid"), "User should be member of first list")
        XCTAssertEqual(viewModel.lists[0].userRole(for: "test-uid"), .owner, "User should be owner of first list")
        XCTAssertEqual(viewModel.lists[0].userRole(for: "other-user"), .editor, "Other user should be editor")
        XCTAssertFalse(viewModel.lists[1].isUserMember("other-user"), "Other user should not be member of second list")
    }
    
    func testMembershipHelpers() {
        // Test the new helper methods on ShoppingList
        let list = ShoppingList(
            id: "test-list",
            name: "Test List",
            description: nil,
            createdBy: "owner-id",
            createdAt: Date(),
            updatedAt: Date(),
            memberIds: ["owner-id", "editor-id", "viewer-id"],
            memberDetails: [
                "owner-id": ShoppingList.ListMember(role: .owner, joinedAt: Date(), displayName: "Owner"),
                "editor-id": ShoppingList.ListMember(role: .editor, joinedAt: Date(), displayName: "Editor"),
                "viewer-id": ShoppingList.ListMember(role: .viewer, joinedAt: Date(), displayName: "Viewer")
            ],
            isArchived: false,
            totalItems: 0,
            completedItems: 0
        )
        
        // Test membership
        XCTAssertTrue(list.isUserMember("owner-id"), "Owner should be member")
        XCTAssertTrue(list.isUserMember("editor-id"), "Editor should be member")
        XCTAssertTrue(list.isUserMember("viewer-id"), "Viewer should be member")
        XCTAssertFalse(list.isUserMember("random-id"), "Random user should not be member")
        
        // Test roles
        XCTAssertEqual(list.userRole(for: "owner-id"), .owner, "Should return owner role")
        XCTAssertEqual(list.userRole(for: "editor-id"), .editor, "Should return editor role")
        XCTAssertEqual(list.userRole(for: "viewer-id"), .viewer, "Should return viewer role")
        XCTAssertNil(list.userRole(for: "random-id"), "Should return nil for non-member")
        
        // Test backward compatibility with members computed property
        XCTAssertEqual(list.members.count, 3, "Should have 3 members via computed property")
        XCTAssertEqual(list.members["owner-id"]?.role, .owner, "Should access role via computed property")
    }
}

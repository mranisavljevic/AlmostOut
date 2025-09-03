//
//  ShareListViewModelTests.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 9/3/25.
//

import XCTest
import Combine
@testable import AlmostOut

@MainActor
class ShareListViewModelTests: XCTestCase {
    var viewModel: ShareListViewModel!
    var mockInviteService: MockInviteService!
    var mockDatabaseService: MockDatabaseService!
    var mockAuthService: MockAuthService!
    var testList: ShoppingList!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockInviteService = MockInviteService()
        mockDatabaseService = MockDatabaseService()
        mockAuthService = MockAuthService()
        cancellables = Set<AnyCancellable>()
        
        testList = createTestList()
        viewModel = ShareListViewModel(
            list: testList,
            inviteService: mockInviteService,
            databaseService: mockDatabaseService,
            authService: mockAuthService
        )
    }
    
    override func tearDown() {
        cancellables = nil
        viewModel = nil
        mockInviteService = nil
        mockDatabaseService = nil
        mockAuthService = nil
        testList = nil
        super.tearDown()
    }
    
    func testCreateShareLinkWithEditorRole() async {
        // Given
        mockAuthService.currentUser = createMockUser(uid: "user1", displayName: "Test User")
        
        // When
        await viewModel.createShareLink(role: .editor)
        
        // Then
        XCTAssertFalse(viewModel.isLoading, "Loading should be false after completion")
        XCTAssertNil(viewModel.errorMessage, "Should not have error message")
        
        // Verify invite service was called with correct data
        XCTAssertEqual(mockInviteService.sentInvitations.count, 1, "Should have sent one invitation")
        XCTAssertEqual(mockInviteService.sentInvitations.first?.role, .editor, "Should create editor invite")
        XCTAssertEqual(mockInviteService.sentInvitations.first?.listId, testList.id, "Should invite to correct list")
    }
    
    func testCreateShareLinkWithViewerRole() async {
        // Given
        mockAuthService.currentUser = createMockUser(uid: "user1", displayName: "Test User")
        
        // When
        await viewModel.createShareLink(role: .viewer)
        
        // Then
        XCTAssertEqual(mockInviteService.sentInvitations.count, 1, "Should have sent one invitation")
        XCTAssertEqual(mockInviteService.sentInvitations.first?.role, .viewer, "Should create viewer invite")
    }
    
    func testCreateShareLinkHandlesError() async {
        // Given
        mockAuthService.currentUser = createMockUser(uid: "user1")
        mockInviteService.shouldFailOperations = true
        
        // When
        await viewModel.createShareLink(role: .editor)
        
        // Then
        XCTAssertFalse(viewModel.isLoading, "Loading should be false after error")
        XCTAssertNotNil(viewModel.errorMessage, "Should have error message")
        XCTAssertEqual(mockInviteService.sentInvitations.count, 0, "Should not have sent invitation on error")
    }
    
    func testCreateShareLinkRequiresAuthentication() async {
        // Given
        mockAuthService.currentUser = nil
        
        // When
        await viewModel.createShareLink(role: .editor)
        
        // Then
        XCTAssertEqual(mockInviteService.sentInvitations.count, 0, "Should not send invitation without auth")
    }
    
    func testCopyShareLink() {
        // Given
        let testInvite = createTestInvite()
        
        // When
        viewModel.copyShareLink(testInvite)
        
        // Then
        XCTAssertEqual(UIPasteboard.general.string, testInvite.shareURL, "Should copy share URL to pasteboard")
    }
    
    func testDeleteShareLink() async {
        // Given
        let testInvite = createTestInvite(id: "test-invite-id")
        
        // When
        viewModel.deleteShareLink(testInvite)
        
        // Then - Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        XCTAssertEqual(mockInviteService.cancelledInvitationIds.count, 1, "Should have cancelled one invitation")
        XCTAssertEqual(mockInviteService.cancelledInvitationIds.first, "test-invite-id", "Should cancel correct invitation")
    }
    
    func testRemoveMember() async {
        // Given
        let userIdToRemove = "user2"
        
        // When
        viewModel.removeMember(userIdToRemove)
        
        // Then - Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertEqual(mockDatabaseService.removedMembers.count, 1, "Should have removed one member")
        XCTAssertEqual(mockDatabaseService.removedMembers.first?.userId, userIdToRemove, "Should remove correct user")
        XCTAssertEqual(mockDatabaseService.removedMembers.first?.listId, testList.id, "Should remove from correct list")
    }
    
    func testCurrentUserId() {
        // Given
        let expectedUserId = "test-user-123"
        mockAuthService.currentUser = createMockUser(uid: expectedUserId)
        
        // Then
        XCTAssertEqual(viewModel.currentUserId, expectedUserId, "Should return current user ID")
    }
    
    func testCurrentUserIdWhenNoUser() {
        // Given
        mockAuthService.currentUser = nil
        
        // Then
        XCTAssertEqual(viewModel.currentUserId, "", "Should return empty string when no user")
    }
    
    // MARK: - Helper Methods
    
    private func createTestList() -> ShoppingList {
        return ShoppingList(
            id: "test-list-id",
            name: "Test List",
            description: "Test Description",
            createdBy: "user1",
            createdAt: Date(),
            updatedAt: Date(),
            memberIds: ["user1", "user2"],
            memberDetails: [
                "user1": ShoppingList.ListMember(
                    role: .owner,
                    joinedAt: Date(),
                    displayName: "Owner User"
                ),
                "user2": ShoppingList.ListMember(
                    role: .editor,
                    joinedAt: Date(),
                    displayName: "Editor User"
                )
            ],
            isArchived: false,
            totalItems: 5,
            completedItems: 2,
            shareSettings: ShoppingList.ShareSettings(allowSharing: true)
        )
    }
    
    private func createTestInvite(id: String = "test-invite") -> ListInvite {
        var invite = ListInvite(
            listId: "test-list-id",
            listName: "Test List",
            invitedBy: "user1",
            invitedByName: "Test User",
            role: .editor
        )
        invite.id = id
        return invite
    }
    
    private func createMockUser(uid: String, displayName: String = "Test User", email: String = "test@example.com") -> MockUser {
        return MockUser(uid: uid, email: email, displayName: displayName)
    }
}
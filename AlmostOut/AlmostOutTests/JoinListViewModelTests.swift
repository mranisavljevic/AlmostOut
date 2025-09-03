//
//  JoinListViewModelTests.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 9/3/25.
//

import XCTest
import Combine
@testable import AlmostOut

@MainActor
class JoinListViewModelTests: XCTestCase {
    var viewModel: JoinListViewModel!
    var mockInviteService: MockInviteService!
    var mockDatabaseService: MockDatabaseService!
    var mockAuthService: MockAuthService!
    var testShareCode: String!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockInviteService = MockInviteService()
        mockDatabaseService = MockDatabaseService()
        mockAuthService = MockAuthService()
        cancellables = Set<AnyCancellable>()
        testShareCode = "ABCD1234"
        
        viewModel = JoinListViewModel(
            shareCode: testShareCode,
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
        testShareCode = nil
        super.tearDown()
    }
    
    func testLoadInvitationSuccess() async {
        // Given
        let testInvite = createTestInvite()
        let testList = createTestList()
        mockDatabaseService.mockLists = [testList]
        
        // Mock the database service to return the test invitation
        // (In a real scenario, this would be set up differently)
        
        // When
        await viewModel.loadInvitation()
        
        // Then
        XCTAssertFalse(viewModel.isLoading, "Loading should be false after completion")
        XCTAssertNil(viewModel.errorMessage, "Should not have error message on success")
    }
    
    func testLoadInvitationWithInvalidShareCode() async {
        // Given
        mockDatabaseService.shouldFailOperations = false
        // No invitation or list setup - simulating invalid share code
        
        // When
        await viewModel.loadInvitation()
        
        // Then
        XCTAssertFalse(viewModel.isLoading, "Loading should be false after completion")
        XCTAssertNotNil(viewModel.errorMessage, "Should have error message for invalid code")
    }
    
    func testJoinListSuccess() async {
        // Given
        mockAuthService.currentUser = createMockUser(uid: "user1")
        let testList = createTestList()
        viewModel.targetList = testList
        mockInviteService.mockJoinedListId = "joined-list-id"
        
        // When
        await viewModel.joinList()
        
        // Then
        XCTAssertFalse(viewModel.isJoining, "Joining should be false after completion")
        XCTAssertTrue(viewModel.joinedSuccessfully, "Should mark as successfully joined")
        XCTAssertNil(viewModel.errorMessage, "Should not have error message")
        
        // Verify service was called
        XCTAssertEqual(mockInviteService.joinedShareCodes.count, 1, "Should have called join service")
        XCTAssertEqual(mockInviteService.joinedShareCodes.first?.shareCode, testShareCode, "Should join with correct share code")
        XCTAssertEqual(mockInviteService.joinedShareCodes.first?.userId, "user1", "Should join with correct user ID")
    }
    
    func testJoinListRequiresAuthentication() async {
        // Given
        mockAuthService.currentUser = nil
        viewModel.targetList = createTestList()
        
        // When
        await viewModel.joinList()
        
        // Then
        XCTAssertFalse(viewModel.isJoining, "Joining should be false")
        XCTAssertFalse(viewModel.joinedSuccessfully, "Should not mark as successfully joined")
        XCTAssertNotNil(viewModel.errorMessage, "Should have authentication error")
        XCTAssertEqual(mockInviteService.joinedShareCodes.count, 0, "Should not call join service without auth")
    }
    
    func testJoinListRequiresTargetList() async {
        // Given
        mockAuthService.currentUser = createMockUser(uid: "user1")
        viewModel.targetList = nil
        
        // When
        await viewModel.joinList()
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage, "Should have error about missing list")
        XCTAssertEqual(mockInviteService.joinedShareCodes.count, 0, "Should not call join service without target list")
    }
    
    func testJoinListHandlesServiceError() async {
        // Given
        mockAuthService.currentUser = createMockUser(uid: "user1")
        viewModel.targetList = createTestList()
        mockInviteService.shouldFailOperations = true
        
        // When
        await viewModel.joinList()
        
        // Then
        XCTAssertFalse(viewModel.isJoining, "Joining should be false after error")
        XCTAssertFalse(viewModel.joinedSuccessfully, "Should not mark as successfully joined on error")
        XCTAssertNotNil(viewModel.errorMessage, "Should have service error message")
    }
    
    func testDeclineInvitationSuccess() async {
        // Given
        mockAuthService.currentUser = createMockUser(uid: "user1")
        let testInvite = createTestInvite(id: "test-invite-id")
        viewModel.invitation = testInvite
        
        // When
        await viewModel.declineInvitation()
        
        // Then
        XCTAssertFalse(viewModel.isDeclining, "Declining should be false after completion")
        XCTAssertNil(viewModel.errorMessage, "Should not have error message")
        
        // Verify service was called
        XCTAssertEqual(mockInviteService.declinedInvitations.count, 1, "Should have declined one invitation")
        XCTAssertEqual(mockInviteService.declinedInvitations.first?.inviteId, "test-invite-id", "Should decline correct invitation")
        XCTAssertEqual(mockInviteService.declinedInvitations.first?.userId, "user1", "Should decline with correct user ID")
    }
    
    func testDeclineInvitationRequiresAuthentication() async {
        // Given
        mockAuthService.currentUser = nil
        viewModel.invitation = createTestInvite()
        
        // When
        await viewModel.declineInvitation()
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage, "Should have authentication error")
        XCTAssertEqual(mockInviteService.declinedInvitations.count, 0, "Should not call decline service without auth")
    }
    
    func testDeclineInvitationRequiresInvitation() async {
        // Given
        mockAuthService.currentUser = createMockUser(uid: "user1")
        viewModel.invitation = nil
        
        // When
        await viewModel.declineInvitation()
        
        // Then - Should return early, no service calls or errors
        XCTAssertEqual(mockInviteService.declinedInvitations.count, 0, "Should not call decline service without invitation")
    }
    
    // MARK: - Helper Methods
    
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
    
    private func createTestList() -> ShoppingList {
        return ShoppingList(
            id: "test-list-id",
            name: "Test List",
            description: "Test Description",
            createdBy: "user1",
            createdAt: Date(),
            updatedAt: Date(),
            memberIds: ["user1"],
            memberDetails: [
                "user1": ShoppingList.ListMember(
                    role: .owner,
                    joinedAt: Date(),
                    displayName: "Owner User"
                )
            ],
            isArchived: false,
            totalItems: 3,
            completedItems: 1,
            shareSettings: ShoppingList.ShareSettings(allowSharing: true)
        )
    }
    
    private func createMockUser(uid: String, displayName: String = "Test User", email: String = "test@example.com") -> MockUser {
        return MockUser(uid: uid, email: email, displayName: displayName)
    }
}
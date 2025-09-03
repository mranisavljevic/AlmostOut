//
//  SharingModelsTests.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 9/3/25.
//

import XCTest
@testable import AlmostOut

class SharingModelsTests: XCTestCase {
    
    // MARK: - ListInvite Tests
    
    func testListInviteInitialization() {
        // Given
        let listId = "test-list"
        let listName = "Test List"
        let invitedBy = "user1"
        let invitedByName = "Test User"
        let role = ShoppingList.ListMember.MemberRole.editor
        
        // When
        let invite = ListInvite(
            listId: listId,
            listName: listName,
            invitedBy: invitedBy,
            invitedByName: invitedByName,
            role: role
        )
        
        // Then
        XCTAssertEqual(invite.listId, listId)
        XCTAssertEqual(invite.listName, listName)
        XCTAssertEqual(invite.invitedBy, invitedBy)
        XCTAssertEqual(invite.invitedByName, invitedByName)
        XCTAssertEqual(invite.role, role)
        XCTAssertEqual(invite.status, .pending)
        XCTAssertEqual(invite.inviteType, .shareLink)
        XCTAssertNotNil(invite.shareCode, "Should generate share code")
        XCTAssertEqual(invite.shareCode.count, 8, "Share code should be 8 characters")
    }
    
    func testListInviteShareURL() {
        // Given
        let invite = createTestInvite()
        
        // When
        let shareURL = invite.shareURL
        
        // Then
        XCTAssertTrue(shareURL.hasPrefix("https://almostout.app/invite/"), "Should have correct URL prefix")
        XCTAssertTrue(shareURL.contains(invite.shareCode), "Should contain share code")
    }
    
    func testListInviteDeepLinkURL() {
        // Given
        let invite = createTestInvite()
        
        // When
        let deepLinkURL = invite.deepLinkURL
        
        // Then
        XCTAssertTrue(deepLinkURL.hasPrefix("almostout://invite/"), "Should have correct deep link prefix")
        XCTAssertTrue(deepLinkURL.contains(invite.shareCode), "Should contain share code")
    }
    
    func testListInviteIsExpired() {
        // Given
        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let futureDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        
        var expiredInvite = createTestInvite()
        expiredInvite.expiresAt = pastDate
        
        var validInvite = createTestInvite()
        validInvite.expiresAt = futureDate
        
        // Then
        XCTAssertTrue(expiredInvite.isExpired, "Should be expired when expiry date is in the past")
        XCTAssertFalse(validInvite.isExpired, "Should not be expired when expiry date is in the future")
    }
    
    func testListInviteCanBeAccepted() {
        // Given
        let futureDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        
        var pendingValidInvite = createTestInvite()
        pendingValidInvite.status = .pending
        pendingValidInvite.expiresAt = futureDate
        
        var acceptedInvite = createTestInvite()
        acceptedInvite.status = .accepted
        acceptedInvite.expiresAt = futureDate
        
        var expiredInvite = createTestInvite()
        expiredInvite.status = .pending
        expiredInvite.expiresAt = pastDate
        
        // Then
        XCTAssertTrue(pendingValidInvite.canBeAccepted, "Should be acceptable when pending and not expired")
        XCTAssertFalse(acceptedInvite.canBeAccepted, "Should not be acceptable when already accepted")
        XCTAssertFalse(expiredInvite.canBeAccepted, "Should not be acceptable when expired")
    }
    
    // MARK: - ShoppingList Tests
    
    func testShoppingListMemberRolePermissions() {
        // Given
        let ownerRole = ShoppingList.ListMember.MemberRole.owner
        let editorRole = ShoppingList.ListMember.MemberRole.editor
        let viewerRole = ShoppingList.ListMember.MemberRole.viewer
        
        // Then - canEdit permissions
        XCTAssertTrue(ownerRole.canEdit, "Owner should be able to edit")
        XCTAssertTrue(editorRole.canEdit, "Editor should be able to edit")
        XCTAssertFalse(viewerRole.canEdit, "Viewer should not be able to edit")
        
        // Then - canManageMembers permissions
        XCTAssertTrue(ownerRole.canManageMembers, "Owner should be able to manage members")
        XCTAssertFalse(editorRole.canManageMembers, "Editor should not be able to manage members")
        XCTAssertFalse(viewerRole.canManageMembers, "Viewer should not be able to manage members")
    }
    
    func testShoppingListUserMembershipChecks() {
        // Given
        let list = createTestShoppingList()
        
        // Then
        XCTAssertTrue(list.isUserMember("user1"), "Should recognize member user")
        XCTAssertTrue(list.isUserMember("user2"), "Should recognize member user")
        XCTAssertFalse(list.isUserMember("user3"), "Should not recognize non-member user")
    }
    
    func testShoppingListOwnershipChecks() {
        // Given
        let list = createTestShoppingList()
        
        // Then
        XCTAssertTrue(list.isUserOwner("user1"), "Should recognize owner user")
        XCTAssertFalse(list.isUserOwner("user2"), "Should not recognize non-owner as owner")
        XCTAssertFalse(list.isUserOwner("user3"), "Should not recognize non-member as owner")
    }
    
    func testShoppingListEditPermissions() {
        // Given
        let list = createTestShoppingList()
        
        // Then
        XCTAssertTrue(list.canUserEdit("user1"), "Owner should be able to edit")
        XCTAssertTrue(list.canUserEdit("user2"), "Editor should be able to edit")
        XCTAssertFalse(list.canUserEdit("user3"), "Non-member should not be able to edit")
    }
    
    func testShoppingListMemberManagementPermissions() {
        // Given
        let list = createTestShoppingList()
        
        // Then
        XCTAssertTrue(list.canUserManageMembers("user1"), "Owner should be able to manage members")
        XCTAssertFalse(list.canUserManageMembers("user2"), "Editor should not be able to manage members")
        XCTAssertFalse(list.canUserManageMembers("user3"), "Non-member should not be able to manage members")
    }
    
    func testShoppingListCanCreateShareLinks() {
        // Given
        let shareableList = createTestShoppingList()
        
        var nonShareableList = shareableList
        nonShareableList.shareSettings = ShoppingList.ShareSettings(allowSharing: false)
        
        // Then
        XCTAssertTrue(shareableList.canCreateShareLinks, "Should allow share link creation when sharing enabled")
        XCTAssertFalse(nonShareableList.canCreateShareLinks, "Should not allow share link creation when sharing disabled")
    }
    
    // MARK: - ListItem Tests
    
    func testListItemUserAttribution() {
        // Given
        let originalItem = createTestListItem()
        
        var editedByDifferentUser = originalItem
        editedByDifferentUser.lastEditedBy = "user2"
        editedByDifferentUser.lastEditedByName = "Different User"
        editedByDifferentUser.lastEditedAt = Date()
        
        var editedBySameUser = originalItem
        editedBySameUser.lastEditedBy = "user1" // Same as addedBy
        editedBySameUser.lastEditedByName = "Test User"
        editedBySameUser.lastEditedAt = Date()
        
        // Then
        XCTAssertFalse(originalItem.hasBeenEdited, "Original item should not show as edited")
        XCTAssertTrue(editedByDifferentUser.hasBeenEdited, "Item edited by different user should show as edited")
        XCTAssertFalse(editedBySameUser.hasBeenEdited, "Item edited by same user should not show as edited")
    }
    
    func testListItemLastModifiedByUser() {
        // Given
        let originalItem = createTestListItem()
        
        var editedItem = originalItem
        editedItem.lastEditedBy = "user2"
        editedItem.lastEditedByName = "Editor User"
        editedItem.lastEditedAt = Date()
        
        // Then
        XCTAssertEqual(originalItem.lastModifiedByUser, "Test User", "Should return original user when not edited")
        XCTAssertEqual(editedItem.lastModifiedByUser, "Editor User", "Should return last editor when edited")
    }
    
    func testListItemLastModificationDate() {
        // Given
        let createdDate = Date()
        let editedDate = Calendar.current.date(byAdding: .hour, value: 1, to: createdDate)!
        
        let originalItem = createTestListItem(createdAt: createdDate)
        
        var editedItem = originalItem
        editedItem.lastEditedAt = editedDate
        
        // Then
        XCTAssertEqual(originalItem.lastModificationDate, createdDate, "Should return creation date when not edited")
        XCTAssertEqual(editedItem.lastModificationDate, editedDate, "Should return edit date when edited")
    }
    
    // MARK: - Helper Methods
    
    private func createTestInvite() -> ListInvite {
        return ListInvite(
            listId: "test-list",
            listName: "Test List",
            invitedBy: "user1",
            invitedByName: "Test User",
            role: .editor
        )
    }
    
    private func createTestShoppingList() -> ShoppingList {
        return ShoppingList(
            id: "test-list",
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
    
    private func createTestListItem(createdAt: Date = Date()) -> ListItem {
        return ListItem(
            id: "test-item",
            name: "Test Item",
            note: "Test Note",
            quantity: "1",
            priority: .normal,
            category: nil,
            addedBy: "user1",
            addedByName: "Test User",
            createdAt: createdAt,
            updatedAt: createdAt,
            lastEditedBy: nil,
            lastEditedByName: nil,
            lastEditedAt: nil,
            isCompleted: false,
            completedBy: nil,
            completedByName: nil,
            completedAt: nil,
            priceGuidance: nil,
            images: [],
            actualPrice: nil,
            storeLocation: nil
        )
    }
}
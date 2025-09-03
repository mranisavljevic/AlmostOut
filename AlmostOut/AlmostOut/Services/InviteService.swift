//
//  InviteService.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 9/3/25.
//

import Foundation
import Combine

protocol InviteServiceProtocol {
    func sendInvitation(_ invite: ListInvite) async throws -> String
    func getIncomingInvitations(for userId: String) -> AnyPublisher<[ListInvite], Error>
    func getOutgoingInvitations(for userId: String) -> AnyPublisher<[ListInvite], Error>
    func acceptInvitation(_ inviteId: String, userId: String) async throws
    func declineInvitation(_ inviteId: String, userId: String) async throws
    func cancelInvitation(_ inviteId: String) async throws
    func resendInvitation(_ inviteId: String) async throws
    func joinListViaShareCode(_ shareCode: String, userId: String) async throws -> String
}

class InviteService: InviteServiceProtocol {
    private let databaseService: DatabaseServiceProtocol
    private let notificationService: NotificationServiceProtocol
    
    init(databaseService: DatabaseServiceProtocol, notificationService: NotificationServiceProtocol) {
        self.databaseService = databaseService
        self.notificationService = notificationService
    }
    
    func sendInvitation(_ invite: ListInvite) async throws -> String {
        // TODO: Implement with FirestoreService
        // Create the invitation document in Firestore
        // Send push notification to the invitee
        // Send email if email invitation
        // Return invitation ID
        throw InviteServiceError.notImplemented
    }
    
    func getIncomingInvitations(for userId: String) -> AnyPublisher<[ListInvite], Error> {
        // TODO: Implement with FirestoreService
        // Query invitations where invitedUserId == userId or invitedEmail == user.email
        let subject = PassthroughSubject<[ListInvite], Error>()
        subject.send(completion: .failure(InviteServiceError.notImplemented))
        return subject.eraseToAnyPublisher()
    }
    
    func getOutgoingInvitations(for userId: String) -> AnyPublisher<[ListInvite], Error> {
        // TODO: Implement with FirestoreService
        // Query invitations where invitedBy == userId
        let subject = PassthroughSubject<[ListInvite], Error>()
        subject.send(completion: .failure(InviteServiceError.notImplemented))
        return subject.eraseToAnyPublisher()
    }
    
    func acceptInvitation(_ inviteId: String, userId: String) async throws {
        // TODO: Implement with FirestoreService
        // Update invitation status to accepted
        // Add user to the list as a member
        // Send notification to list owner
        // Clean up expired/processed invitations
        throw InviteServiceError.notImplemented
    }
    
    func declineInvitation(_ inviteId: String, userId: String) async throws {
        // TODO: Implement with FirestoreService
        // Update invitation status to declined
        // Send notification to list owner
        throw InviteServiceError.notImplemented
    }
    
    func cancelInvitation(_ inviteId: String) async throws {
        // TODO: Implement with FirestoreService
        // Update invitation status to cancelled
        // Send notification to invitee
        throw InviteServiceError.notImplemented
    }
    
    func resendInvitation(_ inviteId: String) async throws {
        // TODO: Implement with FirestoreService
        // Update invitation timestamps
        // Resend notifications
        throw InviteServiceError.notImplemented
    }
    
    func joinListViaShareCode(_ shareCode: String, userId: String) async throws -> String {
        // TODO: Implement with FirestoreService
        // Find list with matching share code
        // Validate share settings
        // Add user as member
        // Return list ID
        throw InviteServiceError.notImplemented
    }
}

class MockInviteService: InviteServiceProtocol {
    // Call tracking properties
    private(set) var sentInvitations: [ListInvite] = []
    private(set) var cancelledInvitationIds: [String] = []
    private(set) var acceptedInvitations: [(inviteId: String, userId: String)] = []
    private(set) var declinedInvitations: [(inviteId: String, userId: String)] = []
    private(set) var joinedShareCodes: [(shareCode: String, userId: String)] = []
    private(set) var resentInvitationIds: [String] = []
    
    // Mock data for returns
    var mockIncomingInvitations: [ListInvite] = []
    var mockOutgoingInvitations: [ListInvite] = []
    var shouldFailOperations = false
    var mockJoinedListId = "mock-joined-list-id"
    
    func sendInvitation(_ invite: ListInvite) async throws -> String {
        if shouldFailOperations {
            throw InviteServiceError.invalidInvitation
        }
        
        sentInvitations.append(invite)
        return UUID().uuidString
    }
    
    func getIncomingInvitations(for userId: String) -> AnyPublisher<[ListInvite], Error> {
        if shouldFailOperations {
            return Fail(error: InviteServiceError.listNotFound)
                .eraseToAnyPublisher()
        }
        
        return Just(mockIncomingInvitations)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func getOutgoingInvitations(for userId: String) -> AnyPublisher<[ListInvite], Error> {
        if shouldFailOperations {
            return Fail(error: InviteServiceError.listNotFound)
                .eraseToAnyPublisher()
        }
        
        return Just(mockOutgoingInvitations)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func acceptInvitation(_ inviteId: String, userId: String) async throws {
        if shouldFailOperations {
            throw InviteServiceError.invitationExpired
        }
        
        acceptedInvitations.append((inviteId: inviteId, userId: userId))
    }
    
    func declineInvitation(_ inviteId: String, userId: String) async throws {
        if shouldFailOperations {
            throw InviteServiceError.invalidInvitation
        }
        
        declinedInvitations.append((inviteId: inviteId, userId: userId))
    }
    
    func cancelInvitation(_ inviteId: String) async throws {
        if shouldFailOperations {
            throw InviteServiceError.insufficientPermissions
        }
        
        cancelledInvitationIds.append(inviteId)
    }
    
    func resendInvitation(_ inviteId: String) async throws {
        if shouldFailOperations {
            throw InviteServiceError.invitationExpired
        }
        
        resentInvitationIds.append(inviteId)
    }
    
    func joinListViaShareCode(_ shareCode: String, userId: String) async throws -> String {
        if shouldFailOperations {
            throw InviteServiceError.listNotFound
        }
        
        joinedShareCodes.append((shareCode: shareCode, userId: userId))
        return mockJoinedListId
    }
    
    // Helper methods for testing
    func reset() {
        sentInvitations.removeAll()
        cancelledInvitationIds.removeAll()
        acceptedInvitations.removeAll()
        declinedInvitations.removeAll()
        joinedShareCodes.removeAll()
        resentInvitationIds.removeAll()
        mockIncomingInvitations.removeAll()
        mockOutgoingInvitations.removeAll()
        shouldFailOperations = false
    }
}

enum InviteServiceError: Error, LocalizedError {
    case notImplemented
    case invalidInvitation
    case invitationExpired
    case userAlreadyMember
    case listNotFound
    case insufficientPermissions
    
    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "Feature not yet implemented"
        case .invalidInvitation:
            return "Invalid invitation"
        case .invitationExpired:
            return "Invitation has expired"
        case .userAlreadyMember:
            return "User is already a member of this list"
        case .listNotFound:
            return "List not found"
        case .insufficientPermissions:
            return "Insufficient permissions to perform this action"
        }
    }
}
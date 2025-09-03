//
//  JoinListViewModel.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 9/3/25.
//

import SwiftUI
import Combine

@MainActor
class JoinListViewModel: ObservableObject {
    @Published var invitation: ListInvite?
    @Published var targetList: ShoppingList?
    @Published var isLoading = false
    @Published var isJoining = false
    @Published var isDeclining = false
    @Published var errorMessage: String?
    @Published var joinedSuccessfully = false
    
    private let shareCode: String
    private let inviteService: InviteServiceProtocol
    private let databaseService: DatabaseServiceProtocol
    private let authService: AuthServiceProtocol
    
    init(
        shareCode: String,
        inviteService: InviteServiceProtocol = InviteService(
            databaseService: FirestoreService(),
            notificationService: FirebaseNotificationService()
        ),
        databaseService: DatabaseServiceProtocol = FirestoreService(),
        authService: AuthServiceProtocol = FirebaseAuthService()
    ) {
        self.shareCode = shareCode
        self.inviteService = inviteService
        self.databaseService = databaseService
        self.authService = authService
    }
    
    func loadInvitation() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // First, find the invitation by share code
            if let foundInvitation = try await databaseService.findInvitationByShareCode(shareCode) {
                invitation = foundInvitation
                
                // Then load the target list details using the listId from the invitation
                targetList = try await databaseService.findListByShareCode(shareCode)
                
                if targetList == nil {
                    errorMessage = "The list associated with this invitation could not be found"
                }
            } else {
                errorMessage = "Invalid or expired share code"
            }
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    
    func joinList() async {
        guard let currentUser = authService.currentUser else {
            errorMessage = "You must be signed in to join a list"
            return
        }
        
        guard let targetList = targetList else {
            errorMessage = "List information not available"
            return
        }
        
        // Check if user is already a member
        if targetList.isUserMember(currentUser.uid) {
            errorMessage = "You are already a member of this list"
            return
        }
        
        isJoining = true
        errorMessage = nil
        
        do {
            let listId = try await inviteService.joinListViaShareCode(shareCode, userId: currentUser.uid)
            joinedSuccessfully = true
            
            // Navigate to the joined list
            // This would typically be handled by the navigation coordinator
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isJoining = false
    }
    
    func declineInvitation() async {
        guard let invitation = invitation else { return }
        guard let inviteId = invitation.id else { return }
        guard let currentUser = authService.currentUser else {
            errorMessage = "You must be signed in to decline an invitation"
            return
        }
        
        isDeclining = true
        errorMessage = nil
        
        do {
            try await inviteService.declineInvitation(inviteId, userId: currentUser.uid)
            // Close the view - invitation is now declined
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isDeclining = false
    }
}
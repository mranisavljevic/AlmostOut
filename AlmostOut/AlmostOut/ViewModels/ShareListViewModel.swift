//
//  ShareListViewModel.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 9/3/25.
//

import SwiftUI
import Combine

@MainActor
class ShareListViewModel: ObservableObject {
    @Published var shareLinks: [ListInvite] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let list: ShoppingList
    private let inviteService: InviteServiceProtocol
    private let databaseService: DatabaseServiceProtocol
    private let authService: AuthServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    var currentUserId: String {
        return authService.currentUser?.uid ?? ""
    }
    
    init(
        list: ShoppingList,
        inviteService: InviteServiceProtocol = InviteService(
            databaseService: FirestoreService(),
            notificationService: FirebaseNotificationService()
        ),
        databaseService: DatabaseServiceProtocol = FirestoreService(),
        authService: AuthServiceProtocol = FirebaseAuthService()
    ) {
        self.list = list
        self.inviteService = inviteService
        self.databaseService = databaseService
        self.authService = authService
        loadShareLinks()
    }
    
    private func loadShareLinks() {
        guard let listId = list.id else { return }
        
        inviteService.getOutgoingInvitations(for: currentUserId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] invites in
                    self?.shareLinks = invites.filter { $0.listId == listId }
                }
            )
            .store(in: &cancellables)
    }
    
    func createShareLink(role: ShoppingList.ListMember.MemberRole) {
        guard let listId = list.id,
              let currentUser = authService.currentUser else { return }
        
        isLoading = true
        
        let invite = ListInvite(
            listId: listId,
            listName: list.name,
            invitedBy: currentUser.uid,
            invitedByName: currentUser.displayName ?? currentUser.email ?? "Unknown",
            role: role
        )
        
        Task {
            do {
                _ = try await inviteService.sendInvitation(invite)
                // Share links will be automatically updated via the observer
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    func copyShareLink(_ shareLink: ListInvite) {
        UIPasteboard.general.string = shareLink.shareURL
        
        // TODO: Show success feedback
        HapticManager.shared.impact(.light)
    }
    
    func shareLink(_ shareLink: ListInvite) {
        let activityVC = UIActivityViewController(
            activityItems: [shareLink.shareURL],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            
            // Handle iPad
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootVC.present(activityVC, animated: true)
        }
    }
    
    func deleteShareLink(_ shareLink: ListInvite) {
        guard let inviteId = shareLink.id else { return }
        
        Task {
            do {
                try await inviteService.cancelInvitation(inviteId)
                // Share links will be automatically updated via the observer
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func removeMember(_ userId: String) {
        guard let listId = list.id else { return }
        
        Task {
            do {
                try await databaseService.removeMemberFromList(userId: userId, from: listId)
                // UI will update automatically via list observers
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// TODO: Move to a proper HapticManager
struct HapticManager {
    static let shared = HapticManager()
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impactGenerator = UIImpactFeedbackGenerator(style: style)
        impactGenerator.impactOccurred()
    }
}
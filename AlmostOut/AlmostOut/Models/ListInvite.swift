//
//  ListInvite.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 9/3/25.
//

import Foundation
import FirebaseFirestore

struct ListInvite: Identifiable, Codable {
    @DocumentID var id: String?
    let listId: String
    let listName: String
    let invitedBy: String
    let invitedByName: String
    let role: ShoppingList.ListMember.MemberRole
    let createdAt: Date
    let expiresAt: Date
    let message: String?
    let status: InviteStatus
    let shareCode: String
    
    enum InviteStatus: String, Codable, CaseIterable {
        case pending, accepted, declined, expired, cancelled
        
        var displayName: String {
            switch self {
            case .pending: return "Pending"
            case .accepted: return "Accepted"
            case .declined: return "Declined"
            case .expired: return "Expired"
            case .cancelled: return "Cancelled"
            }
        }
        
        var isActive: Bool {
            return self == .pending
        }
    }
    
    enum InviteType: String, Codable {
        case shareLink
        
        var displayName: String {
            switch self {
            case .shareLink: return "Share Link"
            }
        }
    }
    
    let inviteType: InviteType
    
    var isExpired: Bool {
        return Date() > expiresAt
    }
    
    var canBeAccepted: Bool {
        return status == .pending && !isExpired
    }
    
    init(
        listId: String,
        listName: String,
        invitedBy: String,
        invitedByName: String,
        role: ShoppingList.ListMember.MemberRole,
        message: String? = nil,
        expirationDays: Int = 30  // Share links last longer
    ) {
        self.listId = listId
        self.listName = listName
        self.invitedBy = invitedBy
        self.invitedByName = invitedByName
        self.role = role
        self.createdAt = Date()
        self.expiresAt = Calendar.current.date(byAdding: .day, value: expirationDays, to: Date()) ?? Date()
        self.message = message
        self.status = .pending
        self.shareCode = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(8).uppercased().description
        self.inviteType = .shareLink
    }
}

extension ListInvite {
    var shareURL: String {
        return "https://almostout.app/invite/\(shareCode)"
    }
    
    var deepLinkURL: String {
        return "almostout://invite/\(shareCode)"
    }
}
//
//  ShoppingList.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/11/25.
//

import Foundation
import FirebaseFirestore

struct ShoppingList: Identifiable, Codable {
    @DocumentID var id: String?
    let name: String
    let description: String?
    let createdBy: String
    let createdAt: Date
    let updatedAt: Date
    let memberIds: [String]  // Changed from members object to array
    let memberDetails: [String: ListMember]  // Keep member details separate
    let isArchived: Bool
    let totalItems: Int
    let completedItems: Int
    let shareSettings: ShareSettings
    
    struct ListMember: Codable {
        let role: MemberRole
        let joinedAt: Date
        let displayName: String
        
        enum MemberRole: String, Codable, CaseIterable {
            case owner, editor, viewer
            
            var displayName: String {
                switch self {
                case .owner: return "Owner"
                case .editor: return "Editor"
                case .viewer: return "Viewer"
                }
            }
            
            var canEdit: Bool {
                switch self {
                case .owner, .editor: return true
                case .viewer: return false
                }
            }
            
            var canManageMembers: Bool {
                return self == .owner
            }
        }
    }
    
    struct ShareSettings: Codable {
        let allowSharing: Bool
        let maxMembers: Int?
        let createdAt: Date
        
        init(allowSharing: Bool = true, maxMembers: Int? = nil) {
            self.allowSharing = allowSharing
            self.maxMembers = maxMembers
            self.createdAt = Date()
        }
    }
    
    var completionPercentage: Double {
        totalItems > 0 ? Double(completedItems) / Double(totalItems) : 0
    }
    
    // Helper computed properties
    var members: [String: ListMember] {
        return memberDetails
    }
    
    func userRole(for userId: String) -> ListMember.MemberRole? {
        return memberDetails[userId]?.role
    }
    
    func isUserMember(_ userId: String) -> Bool {
        return memberIds.contains(userId)
    }
    
    func isUserOwner(_ userId: String) -> Bool {
        return createdBy == userId || memberDetails[userId]?.role == .owner
    }
    
    func canUserEdit(_ userId: String) -> Bool {
        guard let role = memberDetails[userId]?.role else { return false }
        return role.canEdit
    }
    
    func canUserManageMembers(_ userId: String) -> Bool {
        guard let role = memberDetails[userId]?.role else { return false }
        return role.canManageMembers
    }
    
    var canCreateShareLinks: Bool {
        return shareSettings.allowSharing
    }
}

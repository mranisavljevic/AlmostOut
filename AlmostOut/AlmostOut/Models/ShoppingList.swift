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
    
    struct ListMember: Codable {
        let role: MemberRole
        let joinedAt: Date
        let displayName: String
        
        enum MemberRole: String, Codable, CaseIterable {
            case owner, editor, viewer
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
}

//
//  ListItem.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/11/25.
//

import Foundation
import FirebaseFirestore

struct ListItem: Identifiable, Codable {
    @DocumentID var id: String?
    let name: String
    let note: String?
    let quantity: String?
    let priority: Priority
    let category: ItemCategory?
    let addedBy: String
    let addedByName: String
    let createdAt: Date
    let updatedAt: Date
    let isCompleted: Bool
    let completedBy: String?
    let completedByName: String?
    let completedAt: Date?
    let priceGuidance: PriceGuidance?
    let images: [ItemImage]
    let actualPrice: Double?
    let storeLocation: String?
    
    enum Priority: String, Codable, CaseIterable {
        case low, normal, high, urgent
        
        var displayName: String {
            switch self {
            case .low: return "Low"
            case .normal: return "Normal"
            case .high: return "High"
            case .urgent: return "Urgent"
            }
        }
        
        var sortOrder: Int {
            switch self {
            case .urgent: return 0
            case .high: return 1
            case .normal: return 2
            case .low: return 3
            }
        }
    }
}

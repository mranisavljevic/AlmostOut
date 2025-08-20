//
//  ItemImage.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/11/25.
//

import Foundation

struct ItemImage: Codable, Identifiable {
    let id: String
    let url: String
    let thumbnailUrl: String
    let uploadedBy: String
    let uploadedAt: Date
    let filename: String
    let size: Int64
    let type: ImageType
    
    enum ImageType: String, Codable, CaseIterable {
        case reference, receipt, other
        
        var displayName: String {
            switch self {
            case .reference: return "Reference"
            case .receipt: return "Receipt"
            case .other: return "Other"
            }
        }
    }
}

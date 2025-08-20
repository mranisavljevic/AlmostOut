//
//  PriceGuidance.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/11/25.
//

import Foundation

struct PriceGuidance: Codable {
    let type: PriceType
    let exactAmount: Double?
    let maxAmount: Double?
    let rangeMin: Double?
    let rangeMax: Double?
    let qualityLevel: QualityLevel?
    
    enum PriceType: String, Codable, CaseIterable {
        case noPreference = "no_preference"
        case exact = "exact"
        case maxBudget = "max_budget"
        case range = "range"
        case qualityPreference = "quality_preference"
        
        var displayName: String {
            switch self {
            case .noPreference: return "No preference"
            case .exact: return "Exact amount"
            case .maxBudget: return "Maximum budget"
            case .range: return "Price range"
            case .qualityPreference: return "Quality preference"
            }
        }
    }
    
    enum QualityLevel: String, Codable, CaseIterable {
        case cheapest, budget, midRange = "mid_range", premium, highestQuality = "highest_quality"
        
        var displayName: String {
            switch self {
            case .cheapest: return "Cheapest"
            case .budget: return "Budget"
            case .midRange: return "Mid-range"
            case .premium: return "Premium"
            case .highestQuality: return "Highest Quality"
            }
        }
    }
    
    var displayText: String {
        switch type {
        case .noPreference:
            return "No price preference"
        case .exact:
            return exactAmount.map { String(format: "About $%.2f", $0) } ?? ""
        case .maxBudget:
            return maxAmount.map { String(format: "Max $%.2f", $0) } ?? ""
        case .range:
            if let min = rangeMin, let max = rangeMax {
                return String(format: "$%.2f - $%.2f", min, max)
            }
            return ""
        case .qualityPreference:
            return qualityLevel?.displayName ?? ""
        }
    }
}

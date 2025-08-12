//
//  PriceGuidanceTests.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/11/25.
//

import XCTest

class PriceGuidanceTests: XCTestCase {
    
    func testExactPriceDisplay() {
        let priceGuidance = PriceGuidance(
            type: .exact,
            exactAmount: 4.99,
            maxAmount: nil,
            rangeMin: nil,
            rangeMax: nil,
            qualityLevel: nil
        )
        
        XCTAssertEqual(priceGuidance.displayText, "About $4.99")
    }
    
    func testMaxBudgetDisplay() {
        let priceGuidance = PriceGuidance(
            type: .maxBudget,
            exactAmount: nil,
            maxAmount: 10.00,
            rangeMin: nil,
            rangeMax: nil,
            qualityLevel: nil
        )
        
        XCTAssertEqual(priceGuidance.displayText, "Max $10.00")
    }
    
    func testRangeDisplay() {
        let priceGuidance = PriceGuidance(
            type: .range,
            exactAmount: nil,
            maxAmount: nil,
            rangeMin: 5.00,
            rangeMax: 8.00,
            qualityLevel: nil
        )
        
        XCTAssertEqual(priceGuidance.displayText, "$5.00 - $8.00")
    }
    
    func testQualityPreferenceDisplay() {
        let priceGuidance = PriceGuidance(
            type: .qualityPreference,
            exactAmount: nil,
            maxAmount: nil,
            rangeMin: nil,
            rangeMax: nil,
            qualityLevel: .premium
        )
        
        XCTAssertEqual(priceGuidance.displayText, "Premium")
    }
}

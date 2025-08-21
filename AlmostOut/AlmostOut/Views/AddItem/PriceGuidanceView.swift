//
//  PriceGuidanceView.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/21/25.
//

import SwiftUI

struct PriceGuidanceView: View {
    @Binding var priceGuidance: PriceGuidance?
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedType: PriceGuidance.PriceType = .noPreference
    @State private var exactAmount: Double = 0
    @State private var maxAmount: Double = 0
    @State private var rangeMin: Double = 0
    @State private var rangeMax: Double = 0
    @State private var qualityLevel: PriceGuidance.QualityLevel = .midRange
    
    var body: some View {
        NavigationView {
            Form {
                Section("Price Type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(PriceGuidance.PriceType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                }
                
                switch selectedType {
                case .exact:
                    Section("Exact Amount") {
                        HStack {
                            Text("$")
                            TextField("0.00", value: $exactAmount, format: .number.precision(.fractionLength(2)))
                                .keyboardType(.decimalPad)
                        }
                    }
                    
                case .maxBudget:
                    Section("Maximum Budget") {
                        HStack {
                            Text("Don't spend more than $")
                            TextField("0.00", value: $maxAmount, format: .number.precision(.fractionLength(2)))
                                .keyboardType(.decimalPad)
                        }
                    }
                    
                case .range:
                    Section("Price Range") {
                        HStack {
                            Text("From $")
                            TextField("0.00", value: $rangeMin, format: .number.precision(.fractionLength(2)))
                                .keyboardType(.decimalPad)
                        }
                        
                        HStack {
                            Text("To $")
                            TextField("0.00", value: $rangeMax, format: .number.precision(.fractionLength(2)))
                                .keyboardType(.decimalPad)
                        }
                    }
                    
                case .qualityPreference:
                    Section("Quality Level") {
                        Picker("Quality", selection: $qualityLevel) {
                            ForEach(PriceGuidance.QualityLevel.allCases, id: \.self) { level in
                                Text(level.displayName).tag(level)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                    }
                    
                case .noPreference:
                    Section {
                        Text("No price constraints")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Price Guidance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePriceGuidance()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadCurrentValues()
        }
    }
    
    private func loadCurrentValues() {
        guard let current = priceGuidance else { return }
        
        selectedType = current.type
        exactAmount = current.exactAmount ?? 0
        maxAmount = current.maxAmount ?? 0
        rangeMin = current.rangeMin ?? 0
        rangeMax = current.rangeMax ?? 0
        qualityLevel = current.qualityLevel ?? .midRange
    }
    
    private func savePriceGuidance() {
        switch selectedType {
        case .noPreference:
            priceGuidance = nil
            
        case .exact:
            priceGuidance = PriceGuidance(
                type: .exact,
                exactAmount: exactAmount,
                maxAmount: nil,
                rangeMin: nil,
                rangeMax: nil,
                qualityLevel: nil
            )
            
        case .maxBudget:
            priceGuidance = PriceGuidance(
                type: .maxBudget,
                exactAmount: nil,
                maxAmount: maxAmount,
                rangeMin: nil,
                rangeMax: nil,
                qualityLevel: nil
            )
            
        case .range:
            priceGuidance = PriceGuidance(
                type: .range,
                exactAmount: nil,
                maxAmount: nil,
                rangeMin: rangeMin,
                rangeMax: rangeMax,
                qualityLevel: nil
            )
            
        case .qualityPreference:
            priceGuidance = PriceGuidance(
                type: .qualityPreference,
                exactAmount: nil,
                maxAmount: nil,
                rangeMin: nil,
                rangeMax: nil,
                qualityLevel: qualityLevel
            )
        }
    }
}

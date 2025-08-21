//
//  CategoryChip.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/21/25.
//

import SwiftUI

struct CategoryChip: View {
    let name: String
    let isSelected: Bool
    var isCustom: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(name.capitalized)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

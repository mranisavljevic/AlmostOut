//
//  ListRowView.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/21/25.
//

import SwiftUI

struct ListRowView: View {
    let list: ShoppingList
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(list.name)
                    .font(.headline)
                
                Spacer()
                
                if list.completedItems > 0 {
                    ProgressView(value: list.completionPercentage)
                        .frame(width: 60)
                }
            }
            
            if let description = list.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label("\(list.totalItems) items", systemImage: "list.bullet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(list.updatedAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

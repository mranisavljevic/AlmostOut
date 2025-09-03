//
//  ItemRowView.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/21/25.
//

import SwiftUI

struct ItemRowView: View {
    let item: ListItem
    let onToggleComplete: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggleComplete) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isCompleted ? .green : .gray)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .strikethrough(item.isCompleted)
                    .foregroundColor(item.isCompleted ? .secondary : .primary)
                
                if let note = item.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    if let quantity = item.quantity {
                        Label(quantity, systemImage: "number")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if item.priority != .normal {
                        Label(item.priority.displayName, systemImage: priorityIcon(item.priority))
                            .font(.caption)
                            .foregroundColor(priorityColor(item.priority))
                    }
                    
                    if let priceGuidance = item.priceGuidance, priceGuidance.type != .noPreference {
                        Text(priceGuidance.displayText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if !item.images.isEmpty {
                        Image(systemName: "photo")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing) {
            Button("Edit") {
                onEdit()
            }
            .tint(.blue)
        }
    }
    
    private func priorityIcon(_ priority: ListItem.Priority) -> String {
        switch priority {
        case .low: return "arrow.down"
        case .normal: return "minus"
        case .high: return "arrow.up"
        case .urgent: return "exclamationmark"
        }
    }
    
    private func priorityColor(_ priority: ListItem.Priority) -> Color {
        switch priority {
        case .low: return .blue
        case .normal: return .gray
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

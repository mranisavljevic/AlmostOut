//
//  EmptyItemsView.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/21/25.
//

import SwiftUI

struct EmptyItemsView: View {
    let onAddItem: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cart")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("No Items Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add your first item to this shopping list")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Add Item", action: onAddItem)
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
    }
}

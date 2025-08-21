//
//  EmptyListsView.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/21/25.
//

import SwiftUI

struct EmptyListsView: View {
    let onCreateList: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.clipboard")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("No Lists Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first shopping list to get started")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Create List", action: onCreateList)
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
    }
}

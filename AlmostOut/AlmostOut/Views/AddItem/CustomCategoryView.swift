//
//  CustomCategoryView.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/21/25.
//

import SwiftUI

struct CustomCategoryView: View {
    @Binding var categoryName: String
    @Environment(\.dismiss) var dismiss
    let onSave: (String) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Custom Category") {
                    TextField("Category Name", text: $categoryName)
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(categoryName.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }
                    .disabled(categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

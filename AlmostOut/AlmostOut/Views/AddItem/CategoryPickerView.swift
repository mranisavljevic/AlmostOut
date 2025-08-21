//
//  CategoryPickerView.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/21/25.
//

import SwiftUI

struct CategoryPickerView: View {
    @Binding var selectedCategory: ItemCategory?
    @State private var customCategoryName = ""
    @State private var showingCustomCategory = false
    
    private let defaultCategories = FirebaseConstants.defaultCategories
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(defaultCategories, id: \.self) { category in
                    CategoryChip(
                        name: category,
                        isSelected: selectedCategory?.name == category
                    ) {
                        if selectedCategory?.name == category {
                            selectedCategory = nil
                        } else {
                            selectedCategory = ItemCategory(name: category, isCustom: false, scope: .global)
                        }
                    }
                }
                
                CategoryChip(
                    name: "Custom",
                    isSelected: false,
                    isCustom: true
                ) {
                    showingCustomCategory = true
                }
            }
            
            if let category = selectedCategory, category.isCustom {
                Text("Custom: \(category.name)")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .sheet(isPresented: $showingCustomCategory) {
            CustomCategoryView(categoryName: $customCategoryName) { name in
                selectedCategory = ItemCategory(name: name, isCustom: true, scope: .user)
            }
        }
    }
}

//
//  FilterView.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/21/25.
//

import SwiftUI

struct FilterView: View {
    @ObservedObject var viewModel: ListDetailViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Show Items") {
                    Toggle("Show Completed Items", isOn: $viewModel.showCompletedItems)
                }
                
                Section("Category") {
                    Picker("Category", selection: $viewModel.selectedCategory) {
                        Text("All Categories").tag(String?.none)
                        ForEach(viewModel.categories, id: \.self) { category in
                            Text(category.capitalized).tag(String?.some(category))
                        }
                    }
                }
                
                Section("Sort By") {
                    Picker("Sort Option", selection: $viewModel.sortOption) {
                        ForEach(ListDetailViewModel.SortOption.allCases, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                }
            }
            .navigationTitle("Filter & Sort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

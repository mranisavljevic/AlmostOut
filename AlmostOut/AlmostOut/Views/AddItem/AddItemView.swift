//
//  AddItemView.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/21/25.
//

import PhotosUI
import SwiftUI

struct AddItemView: View {
    let listId: String
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: AddItemViewModel
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showingPriceGuidance = false
    
    init(listId: String) {
        self.listId = listId
        self._viewModel = StateObject(wrappedValue: AddItemViewModel(listId: listId))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Item Details") {
                    TextField("Item Name", text: $viewModel.name)
                    TextField("Notes (Optional)", text: $viewModel.note, axis: .vertical)
                        .lineLimit(3)
                    TextField("Quantity (Optional)", text: $viewModel.quantity)
                }
                
                Section("Priority") {
                    Picker("Priority", selection: $viewModel.priority) {
                        ForEach(ListItem.Priority.allCases, id: \.self) { priority in
                            Text(priority.displayName).tag(priority)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("Category") {
                    CategoryPickerView(selectedCategory: $viewModel.selectedCategory)
                }
                
                Section("Price Guidance") {
                    Button("Set Price Guidance") {
                        showingPriceGuidance = true
                    }
                    
                    if let priceGuidance = viewModel.priceGuidance {
                        Text(priceGuidance.displayText)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Photos") {
                    PhotosPickerView(selectedImages: $viewModel.selectedImages)
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        Task {
                            let success = await viewModel.addItem()
                            if success {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isLoading)
                }
            }
            .sheet(isPresented: $showingPriceGuidance) {
                PriceGuidanceView(priceGuidance: $viewModel.priceGuidance)
            }
        }
    }
}

#Preview("Add Item View") {
    AddItemView(listId: "preview-list")
}

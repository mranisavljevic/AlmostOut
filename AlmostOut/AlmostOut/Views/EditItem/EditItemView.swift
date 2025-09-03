//
//  EditItemView.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/26/25.
//

import PhotosUI
import SwiftUI

struct EditItemView: View {
    let listId: String
    let item: ListItem
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: EditItemViewModel
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showingPriceGuidance = false
    
    init(listId: String, item: ListItem) {
        self.listId = listId
        self.item = item
        self._viewModel = StateObject(wrappedValue: EditItemViewModel(listId: listId, item: item))
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
                    
                    if !item.images.isEmpty {
                        Text("Existing photos will be preserved")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            let success = await viewModel.updateItem()
                            if success {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.isValid || !viewModel.hasChanges || viewModel.isLoading)
                }
            }
            .sheet(isPresented: $showingPriceGuidance) {
                PriceGuidanceView(priceGuidance: $viewModel.priceGuidance)
            }
        }
    }
}

#Preview("Edit Item View") {
    EditItemView(
        listId: "preview-list",
        item: ListItem(
            id: "preview-item",
            name: "Sample Item",
            note: "Sample note",
            quantity: "2",
            priority: .normal,
            category: nil,
            addedBy: "user1",
            addedByName: "User One",
            createdAt: Date(),
            updatedAt: Date(),
            lastEditedBy: nil,
            lastEditedByName: nil,
            lastEditedAt: nil,
            isCompleted: false,
            completedBy: nil,
            completedByName: nil,
            completedAt: nil,
            priceGuidance: nil,
            images: [],
            actualPrice: nil,
            storeLocation: nil
        )
    )
}
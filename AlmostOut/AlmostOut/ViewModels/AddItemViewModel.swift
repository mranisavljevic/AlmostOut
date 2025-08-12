//
//  AddItemViewModel.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/11/25.
//

import SwiftUI

@MainActor
class AddItemViewModel: ObservableObject {
    @Published var name = ""
    @Published var note = ""
    @Published var quantity = ""
    @Published var priority: ListItem.Priority = .normal
    @Published var selectedCategory: ItemCategory?
    @Published var priceGuidance: PriceGuidance?
    @Published var selectedImages: [UIImage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let listId: String
    private let databaseService: DatabaseServiceProtocol
    private let storageService: StorageServiceProtocol
    private let authService: AuthServiceProtocol
    
    init(
        listId: String,
        databaseService: DatabaseServiceProtocol = FirestoreService(),
        storageService: StorageServiceProtocol = FirebaseStorageService(),
        authService: AuthServiceProtocol = FirebaseAuthService()
    ) {
        self.listId = listId
        self.databaseService = databaseService
        self.storageService = storageService
        self.authService = authService
    }
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func addItem() async -> Bool {
        guard isValid,
              let userId = authService.currentUser?.uid,
              let displayName = authService.currentUser?.displayName else { return false }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Create the item first
            let newItem = ListItem(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                note: note.isEmpty ? nil : note.trimmingCharacters(in: .whitespacesAndNewlines),
                quantity: quantity.isEmpty ? nil : quantity.trimmingCharacters(in: .whitespacesAndNewlines),
                priority: priority,
                category: selectedCategory,
                addedBy: userId,
                addedByName: displayName,
                createdAt: Date(),
                updatedAt: Date(),
                isCompleted: false,
                completedBy: nil,
                completedByName: nil,
                completedAt: nil,
                priceGuidance: priceGuidance,
                images: [], // Will be updated after upload
                actualPrice: nil,
                storeLocation: nil
            )
            
            let itemId = try await databaseService.addItem(newItem, to: listId)
            
            // Upload images if any
            if !selectedImages.isEmpty {
                var uploadedImages: [ItemImage] = []
                
                for image in selectedImages {
                    if let compressedData = ImageProcessor.compressImage(image) {
                        let uploadedImage = try await storageService.uploadImage(
                            compressedData,
                            for: itemId,
                            in: listId,
                            type: .reference
                        )
                        uploadedImages.append(uploadedImage)
                    }
                }
                
                // Update item with image URLs
                if !uploadedImages.isEmpty {
                    let updatedItem = ListItem(
                        id: itemId,
                        name: newItem.name,
                        note: newItem.note,
                        quantity: newItem.quantity,
                        priority: newItem.priority,
                        category: newItem.category,
                        addedBy: newItem.addedBy,
                        addedByName: newItem.addedByName,
                        createdAt: newItem.createdAt,
                        updatedAt: Date(),
                        isCompleted: newItem.isCompleted,
                        completedBy: newItem.completedBy,
                        completedByName: newItem.completedByName,
                        completedAt: newItem.completedAt,
                        priceGuidance: newItem.priceGuidance,
                        images: uploadedImages,
                        actualPrice: newItem.actualPrice,
                        storeLocation: newItem.storeLocation
                    )
                    
                    try await databaseService.updateItem(updatedItem, in: listId)
                }
            }
            
            // Reset form
            resetForm()
            isLoading = false
            return true
            
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    private func resetForm() {
        name = ""
        note = ""
        quantity = ""
        priority = .normal
        selectedCategory = nil
        priceGuidance = nil
        selectedImages = []
    }
}

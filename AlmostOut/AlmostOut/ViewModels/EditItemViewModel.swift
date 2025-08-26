//
//  EditItemViewModel.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/26/25.
//

import SwiftUI

@MainActor
class EditItemViewModel: ObservableObject {
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
    private let originalItem: ListItem
    private let databaseService: DatabaseServiceProtocol
    private let storageService: StorageServiceProtocol
    private let authService: AuthServiceProtocol
    
    init(
        listId: String,
        item: ListItem,
        databaseService: DatabaseServiceProtocol = FirestoreService(),
        storageService: StorageServiceProtocol = FirebaseStorageService(),
        authService: AuthServiceProtocol = FirebaseAuthService()
    ) {
        self.listId = listId
        self.originalItem = item
        self.databaseService = databaseService
        self.storageService = storageService
        self.authService = authService
        
        // Pre-populate fields with existing item data
        self.name = item.name
        self.note = item.note ?? ""
        self.quantity = item.quantity ?? ""
        self.priority = item.priority
        self.selectedCategory = item.category
        self.priceGuidance = item.priceGuidance
        // Note: We're not loading existing images into selectedImages for now
        // as that would require converting from URLs to UIImages
    }
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var hasChanges: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedQuantity = quantity.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return trimmedName != originalItem.name ||
               (trimmedNote.isEmpty ? nil : trimmedNote) != originalItem.note ||
               (trimmedQuantity.isEmpty ? nil : trimmedQuantity) != originalItem.quantity ||
               priority != originalItem.priority ||
               selectedCategory != originalItem.category ||
               priceGuidance != originalItem.priceGuidance ||
               !selectedImages.isEmpty
    }
    
    func updateItem() async -> Bool {
        guard isValid, hasChanges else { return false }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Upload new images if any
            var allImages = originalItem.images
            if !selectedImages.isEmpty {
                var uploadedImages: [ItemImage] = []
                
                for image in selectedImages {
                    if let compressedData = ImageProcessor.compressImage(image) {
                        let uploadedImage = try await storageService.uploadImage(
                            compressedData,
                            for: originalItem.id ?? "",
                            in: listId,
                            type: .reference
                        )
                        uploadedImages.append(uploadedImage)
                    }
                }
                
                allImages.append(contentsOf: uploadedImages)
            }
            
            // Create updated item
            let updatedItem = ListItem(
                id: originalItem.id,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                note: note.isEmpty ? nil : note.trimmingCharacters(in: .whitespacesAndNewlines),
                quantity: quantity.isEmpty ? nil : quantity.trimmingCharacters(in: .whitespacesAndNewlines),
                priority: priority,
                category: selectedCategory,
                addedBy: originalItem.addedBy,
                addedByName: originalItem.addedByName,
                createdAt: originalItem.createdAt,
                updatedAt: Date(),
                isCompleted: originalItem.isCompleted,
                completedBy: originalItem.completedBy,
                completedByName: originalItem.completedByName,
                completedAt: originalItem.completedAt,
                priceGuidance: priceGuidance,
                images: allImages,
                actualPrice: originalItem.actualPrice,
                storeLocation: originalItem.storeLocation
            )
            
            try await databaseService.updateItem(updatedItem, in: listId)
            
            isLoading = false
            return true
            
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
}
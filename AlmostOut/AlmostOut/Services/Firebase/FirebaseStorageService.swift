//
//  FirebaseStorageService.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/12/25.
//

import FirebaseAuth
import FirebaseStorage
import Foundation

class FirebaseStorageService: StorageServiceProtocol {
    private let storage = Storage.storage()
    
    func uploadImage(_ imageData: Data, for itemId: String, in listId: String, type: ItemImage.ImageType) async throws -> ItemImage {
        let imageId = UUID().uuidString
        let filename = "\(imageId).jpg"
        let path = "\(StorageConstants.shoppingListsFolder)/\(listId)/items/\(itemId)/\(StorageConstants.imagesFolder)/\(filename)"
        
        let storageRef = storage.reference().child(path)
        
        // Upload original image
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let uploadTask = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        
        // Generate and upload thumbnail
        let thumbnailPath = "\(StorageConstants.shoppingListsFolder)/\(listId)/items/\(itemId)/\(StorageConstants.imagesFolder)/\(imageId)\(StorageConstants.thumbnailSuffix).jpg"
        let thumbnailRef = storage.reference().child(thumbnailPath)
        
        // For now, we'll use the same image as thumbnail
        // In production, you'd want to resize it first
        let thumbnailUploadTask = try await thumbnailRef.putDataAsync(imageData, metadata: metadata)
        let thumbnailURL = try await thumbnailRef.downloadURL()
        
        return ItemImage(
            id: imageId,
            url: downloadURL.absoluteString,
            thumbnailUrl: thumbnailURL.absoluteString,
            uploadedBy: Auth.auth().currentUser?.uid ?? "",
            uploadedAt: Date(),
            filename: filename,
            size: Int64(imageData.count),
            type: type
        )
    }
    
    func deleteImage(at url: String) async throws {
        let storageRef = storage.reference(forURL: url)
        try await storageRef.delete()
    }
}

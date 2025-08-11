//
//  MockStorageService.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/11/25.
//

import Foundation

class MockStorageService: StorageServiceProtocol {
    var shouldFailUpload = false
    var uploadedImages: [ItemImage] = []
    
    func uploadImage(_ imageData: Data, for itemId: String, in listId: String, type: ItemImage.ImageType) async throws -> ItemImage {
        if shouldFailUpload {
            throw NSError(domain: "MockError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Upload failed"])
        }
        
        let image = ItemImage(
            id: UUID().uuidString,
            url: "https://mock-storage.com/image.jpg",
            thumbnailUrl: "https://mock-storage.com/thumb.jpg",
            uploadedBy: "test-uid",
            uploadedAt: Date(),
            filename: "test_image.jpg",
            size: Int64(imageData.count),
            type: type
        )
        
        uploadedImages.append(image)
        return image
    }
    
    func deleteImage(at url: String) async throws {
        uploadedImages.removeAll { $0.url == url }
    }
}

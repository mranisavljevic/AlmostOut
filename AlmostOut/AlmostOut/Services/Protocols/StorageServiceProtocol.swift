//
//  StorageServiceProtocol.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/11/25.
//

import Foundation

protocol StorageServiceProtocol {
    func uploadImage(_ imageData: Data, for itemId: String, in listId: String, type: ItemImage.ImageType) async throws -> ItemImage
    func deleteImage(at url: String) async throws
}

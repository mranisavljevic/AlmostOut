//
//  SharingService.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 9/3/25.
//

import Foundation
import Combine

protocol SharingServiceProtocol {
    func generateShareLink(for list: ShoppingList) -> String?
    func validateShareCode(_ shareCode: String) async throws -> ShoppingList?
    func createShareableList(_ list: ShoppingList) async throws -> ShoppingList
    func updateShareSettings(_ settings: ShoppingList.ShareSettings, for listId: String) async throws
    func deactivateSharing(for listId: String) async throws
}

class SharingService: SharingServiceProtocol {
    private let databaseService: DatabaseServiceProtocol
    
    init(databaseService: DatabaseServiceProtocol) {
        self.databaseService = databaseService
    }
    
    func generateShareLink(for list: ShoppingList) -> String? {
        return list.shareableURL
    }
    
    func validateShareCode(_ shareCode: String) async throws -> ShoppingList? {
        // This would query Firestore for a list with the matching share code
        // For now, returning nil - will be implemented with FirestoreService updates
        return nil
    }
    
    func createShareableList(_ list: ShoppingList) async throws -> ShoppingList {
        var updatedList = list
        updatedList.shareSettings = ShoppingList.ShareSettings()
        return updatedList
    }
    
    func updateShareSettings(_ settings: ShoppingList.ShareSettings, for listId: String) async throws {
        // This would update the list's share settings in Firestore
        // Implementation will follow with FirestoreService updates
    }
    
    func deactivateSharing(for listId: String) async throws {
        let disabledSettings = ShoppingList.ShareSettings(
            allowSharing: false,
            maxMembers: nil
        )
        try await updateShareSettings(disabledSettings, for: listId)
    }
}

class MockSharingService: SharingServiceProtocol {
    func generateShareLink(for list: ShoppingList) -> String? {
        return "https://almostout.app/join/MOCK1234"
    }
    
    func validateShareCode(_ shareCode: String) async throws -> ShoppingList? {
        return nil
    }
    
    func createShareableList(_ list: ShoppingList) async throws -> ShoppingList {
        var updatedList = list
        updatedList.shareSettings = ShoppingList.ShareSettings()
        return updatedList
    }
    
    func updateShareSettings(_ settings: ShoppingList.ShareSettings, for listId: String) async throws {
        // Mock implementation - no-op
    }
    
    func deactivateSharing(for listId: String) async throws {
        // Mock implementation - no-op
    }
}
//
//  EditItemViewModelTests.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/26/25.
//

import XCTest
@testable import AlmostOut

@MainActor
class EditItemViewModelTests: XCTestCase {
    var viewModel: EditItemViewModel!
    var mockDatabaseService: MockDatabaseService!
    var mockStorageService: MockStorageService!
    var mockAuthService: MockAuthService!
    var testItem: ListItem!
    
    override func setUp() {
        super.setUp()
        mockDatabaseService = MockDatabaseService()
        mockStorageService = MockStorageService()
        mockAuthService = MockAuthService()
        
        testItem = createTestItem()
        
        viewModel = EditItemViewModel(
            listId: "test-list",
            item: testItem,
            databaseService: mockDatabaseService,
            storageService: mockStorageService,
            authService: mockAuthService
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockDatabaseService = nil
        mockStorageService = nil
        mockAuthService = nil
        testItem = nil
        super.tearDown()
    }
    
    func testInitializationWithExistingItem() {
        // Then - ViewModel should be pre-populated with existing item data
        XCTAssertEqual(viewModel.name, "Test Item")
        XCTAssertEqual(viewModel.note, "Test note")
        XCTAssertEqual(viewModel.quantity, "2")
        XCTAssertEqual(viewModel.priority, .high)
        XCTAssertEqual(viewModel.selectedCategory?.name, "dairy")
        XCTAssertEqual(viewModel.priceGuidance?.type, .maxBudget)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testIsValidWithValidName() {
        // Given - Valid name
        viewModel.name = "Valid Item Name"
        
        // Then
        XCTAssertTrue(viewModel.isValid)
    }
    
    func testIsValidWithEmptyName() {
        // Given - Empty name
        viewModel.name = ""
        
        // Then
        XCTAssertFalse(viewModel.isValid)
    }
    
    func testIsValidWithWhitespaceOnlyName() {
        // Given - Whitespace only name
        viewModel.name = "   \t\n  "
        
        // Then
        XCTAssertFalse(viewModel.isValid)
    }
    
    func testHasChangesWhenNoChanges() {
        // Given - No changes made to the item
        // When - Check if there are changes
        // Then
        XCTAssertFalse(viewModel.hasChanges, "Should have no changes when nothing is modified")
    }
    
    func testHasChangesWhenNameChanged() {
        // Given - Change the name
        viewModel.name = "Updated Item Name"
        
        // When - Check if there are changes
        // Then
        XCTAssertTrue(viewModel.hasChanges, "Should detect changes when name is modified")
    }
    
    func testHasChangesWhenNoteChanged() {
        // Given - Change the note
        viewModel.note = "Updated note"
        
        // When - Check if there are changes
        // Then
        XCTAssertTrue(viewModel.hasChanges, "Should detect changes when note is modified")
    }
    
    func testHasChangesWhenQuantityChanged() {
        // Given - Change the quantity
        viewModel.quantity = "5"
        
        // When - Check if there are changes
        // Then
        XCTAssertTrue(viewModel.hasChanges, "Should detect changes when quantity is modified")
    }
    
    func testHasChangesWhenPriorityChanged() {
        // Given - Change the priority
        viewModel.priority = .urgent
        
        // When - Check if there are changes
        // Then
        XCTAssertTrue(viewModel.hasChanges, "Should detect changes when priority is modified")
    }
    
    func testHasChangesWhenCategoryChanged() {
        // Given - Change the category
        viewModel.selectedCategory = ItemCategory(name: "bakery", isCustom: false, scope: .global)
        
        // When - Check if there are changes
        // Then
        XCTAssertTrue(viewModel.hasChanges, "Should detect changes when category is modified")
    }
    
    func testHasChangesWhenPriceGuidanceChanged() {
        // Given - Change the price guidance
        viewModel.priceGuidance = PriceGuidance(
            type: .qualityPreference,
            exactAmount: nil,
            maxAmount: nil,
            rangeMin: nil,
            rangeMax: nil,
            qualityLevel: .premium
        )
        
        // When - Check if there are changes
        // Then
        XCTAssertTrue(viewModel.hasChanges, "Should detect changes when price guidance is modified")
    }
    
    func testHasChangesWhenImagesAdded() {
        // Given - Add new images
        let testImage = UIImage(systemName: "photo") ?? UIImage()
        viewModel.selectedImages = [testImage]
        
        // When - Check if there are changes
        // Then
        XCTAssertTrue(viewModel.hasChanges, "Should detect changes when new images are added")
    }
    
    func testHasChangesWithNoteRemovedWhenOriginallyHadNote() {
        // Given - Remove the note (set to empty)
        viewModel.note = ""
        
        // When - Check if there are changes
        // Then
        XCTAssertTrue(viewModel.hasChanges, "Should detect changes when note is removed")
    }
    
    func testHasChangesWithQuantityRemovedWhenOriginallyHadQuantity() {
        // Given - Remove the quantity (set to empty)
        viewModel.quantity = ""
        
        // When - Check if there are changes
        // Then
        XCTAssertTrue(viewModel.hasChanges, "Should detect changes when quantity is removed")
    }
    
    func testUpdateItemSuccessWithChanges() async {
        // Given - Make changes to the item
        viewModel.name = "Updated Item"
        viewModel.note = "Updated note"
        
        mockAuthService.currentUser = User(
            uid: "test-uid",
            email: "test@example.com",
            displayName: "Test User",
            profileImageUrl: nil,
            createdAt: Date(),
            updatedAt: Date(),
            preferences: User.UserPreferences(),
            fcmTokens: []
        )
        
        // When - Update the item
        let success = await viewModel.updateItem()
        
        // Then
        XCTAssertTrue(success, "Should successfully update the item")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after completion")
        XCTAssertNil(viewModel.errorMessage, "Should not have an error message")
    }
    
    func testUpdateItemFailsWithoutChanges() async {
        // Given - No changes made to the item
        
        // When - Attempt to update the item
        let success = await viewModel.updateItem()
        
        // Then
        XCTAssertFalse(success, "Should not update when there are no changes")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading")
    }
    
    func testUpdateItemFailsWithInvalidName() async {
        // Given - Invalid name (empty)
        viewModel.name = ""
        
        // When - Attempt to update the item
        let success = await viewModel.updateItem()
        
        // Then
        XCTAssertFalse(success, "Should not update with invalid name")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading")
    }
    
    func testUpdateItemWithImageUpload() async {
        // Given - Add new images and make other changes
        let testImage = UIImage(systemName: "photo") ?? UIImage()
        viewModel.selectedImages = [testImage]
        viewModel.name = "Updated with Image"
        
        mockAuthService.currentUser = User(
            uid: "test-uid",
            email: "test@example.com",
            displayName: "Test User",
            profileImageUrl: nil,
            createdAt: Date(),
            updatedAt: Date(),
            preferences: User.UserPreferences(),
            fcmTokens: []
        )
        
        // When - Update the item
        let success = await viewModel.updateItem()
        
        // Then
        XCTAssertTrue(success, "Should successfully update the item with images")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after completion")
        XCTAssertNil(viewModel.errorMessage, "Should not have an error message")
    }
    
    func testLoadingStatesDuringUpdate() async {
        // Given - Make changes
        viewModel.name = "Updated Item"
        
        mockAuthService.currentUser = User(
            uid: "test-uid",
            email: "test@example.com",
            displayName: "Test User",
            profileImageUrl: nil,
            createdAt: Date(),
            updatedAt: Date(),
            preferences: User.UserPreferences(),
            fcmTokens: []
        )
        
        // When - Start update (we can't easily test the loading state mid-update with current setup)
        let success = await viewModel.updateItem()
        
        // Then - After completion
        XCTAssertTrue(success, "Should successfully update")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading after completion")
    }
    
    private func createTestItem() -> ListItem {
        return ListItem(
            id: "test-item-id",
            name: "Test Item",
            note: "Test note",
            quantity: "2",
            priority: .high,
            category: ItemCategory(name: "dairy", isCustom: false, scope: .global),
            addedBy: "test-uid",
            addedByName: "Test User",
            createdAt: Date(),
            updatedAt: Date(),
            isCompleted: false,
            completedBy: nil,
            completedByName: nil,
            completedAt: nil,
            priceGuidance: PriceGuidance(
                type: .maxBudget,
                exactAmount: nil,
                maxAmount: 10.0,
                rangeMin: nil,
                rangeMax: nil,
                qualityLevel: nil
            ),
            images: [],
            actualPrice: nil,
            storeLocation: nil
        )
    }
}
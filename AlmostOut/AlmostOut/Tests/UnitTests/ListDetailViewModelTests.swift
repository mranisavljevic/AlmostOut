//
//  ListDetailViewModelTests.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/11/25.
//

import XCTest

class ListDetailViewModelTests: XCTestCase {
    var viewModel: ListDetailViewModel!
    var mockDatabaseService: MockDatabaseService!
    var mockAuthService: MockAuthService!
    
    override func setUp() {
        super.setUp()
        mockDatabaseService = MockDatabaseService()
        mockAuthService = MockAuthService()
        viewModel = ListDetailViewModel(
            listId: "test-list",
            databaseService: mockDatabaseService,
            authService: mockAuthService
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockDatabaseService = nil
        mockAuthService = nil
        super.tearDown()
    }
    
    func testItemFiltering() async {
        // Given
        let items = [
            createMockItem(name: "Milk", isCompleted: false, category: "dairy"),
            createMockItem(name: "Bread", isCompleted: true, category: "bakery"),
            createMockItem(name: "Cheese", isCompleted: false, category: "dairy")
        ]
        mockDatabaseService.mockItems = items
        
        // When
        viewModel.searchText = "milk"
        
        // Give some time for the filtering to process
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertEqual(viewModel.filteredItems.count, 1)
        XCTAssertEqual(viewModel.filteredItems.first?.name, "Milk")
    }
    
    func testCategoryFiltering() async {
        // Given
        let items = [
            createMockItem(name: "Milk", isCompleted: false, category: "dairy"),
            createMockItem(name: "Bread", isCompleted: false, category: "bakery"),
            createMockItem(name: "Cheese", isCompleted: false, category: "dairy")
        ]
        mockDatabaseService.mockItems = items
        
        // When
        viewModel.selectedCategory = "dairy"
        
        // Give some time for the filtering to process
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertEqual(viewModel.filteredItems.count, 2)
        XCTAssertTrue(viewModel.filteredItems.allSatisfy { $0.category?.name == "dairy" })
    }
    
    func testToggleItemCompletion() async {
        // Given
        let item = createMockItem(name: "Milk", isCompleted: false)
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
        
        // When
        await viewModel.toggleItemCompletion(item)
        
        // Then
        XCTAssertNil(viewModel.errorMessage)
        // Verify the update was called (in a real test, you might verify the exact parameters)
    }
    
    private func createMockItem(name: String, isCompleted: Bool, category: String? = nil) -> ListItem {
        return ListItem(
            id: UUID().uuidString,
            name: name,
            note: nil,
            quantity: nil,
            priority: .normal,
            category: category.map { ItemCategory(name: $0, isCustom: false, scope: .global) },
            addedBy: "test-uid",
            addedByName: "Test User",
            createdAt: Date(),
            updatedAt: Date(),
            isCompleted: isCompleted,
            completedBy: isCompleted ? "test-uid" : nil,
            completedByName: isCompleted ? "Test User" : nil,
            completedAt: isCompleted ? Date() : nil,
            priceGuidance: nil,
            images: [],
            actualPrice: nil,
            storeLocation: nil
        )
    }
}

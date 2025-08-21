//
//  ListDetailViewModelTests.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/11/25.
//

import XCTest
@testable import AlmostOut

@MainActor
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
    
    func testItemFiltering() {
        // Given - Set up test data directly on the ViewModel
        let items = [
            createMockItem(name: "Milk", isCompleted: false, category: "dairy"),
            createMockItem(name: "Bread", isCompleted: true, category: "bakery"),
            createMockItem(name: "Cheese", isCompleted: false, category: "dairy")
        ]
        
        // Directly set the items on the ViewModel (bypassing the service layer for testing)
        viewModel.items = items
        
        // When - Apply search filter
        viewModel.searchText = "milk"
        
        // Then - Check filtering results
        XCTAssertEqual(viewModel.filteredItems.count, 1, "Should filter to 1 item")
        XCTAssertEqual(viewModel.filteredItems.first?.name, "Milk", "Should find the Milk item")
    }
    
    func testCategoryFiltering() {
        // Given
        let items = [
            createMockItem(name: "Milk", isCompleted: false, category: "dairy"),
            createMockItem(name: "Bread", isCompleted: false, category: "bakery"),
            createMockItem(name: "Cheese", isCompleted: false, category: "dairy")
        ]
        
        viewModel.items = items
        
        // When
        viewModel.selectedCategory = "dairy"
        
        // Then
        XCTAssertEqual(viewModel.filteredItems.count, 2, "Should filter to 2 dairy items")
        XCTAssertTrue(viewModel.filteredItems.allSatisfy { $0.category?.name == "dairy" }, "All items should be dairy")
    }
    
    func testShowCompletedItemsToggle() {
        // Given
        let items = [
            createMockItem(name: "Milk", isCompleted: false, category: "dairy"),
            createMockItem(name: "Bread", isCompleted: true, category: "bakery"),
            createMockItem(name: "Cheese", isCompleted: false, category: "dairy")
        ]
        
        viewModel.items = items
        
        // When hiding completed items
        viewModel.showCompletedItems = false
        
        // Then - Should only show incomplete items
        XCTAssertEqual(viewModel.filteredItems.count, 2, "Should show 2 incomplete items")
        XCTAssertTrue(viewModel.filteredItems.allSatisfy { !$0.isCompleted }, "All items should be incomplete")
        
        // When showing completed items again
        viewModel.showCompletedItems = true
        
        // Then - Should show all items
        XCTAssertEqual(viewModel.filteredItems.count, 3, "Should show all 3 items")
    }
    
    func testSortingByPriority() {
        // Given
        let items = [
            createMockItem(name: "Milk", isCompleted: false, priority: .normal),
            createMockItem(name: "Bread", isCompleted: false, priority: .urgent),
            createMockItem(name: "Cheese", isCompleted: false, priority: .low)
        ]
        
        viewModel.items = items
        viewModel.sortOption = .priority
        
        // Then - Should be sorted by priority (urgent, normal, low)
        let sortedItems = viewModel.filteredItems
        XCTAssertEqual(sortedItems.count, 3)
        XCTAssertEqual(sortedItems[0].name, "Bread") // urgent first
        XCTAssertEqual(sortedItems[1].name, "Milk")  // normal second
        XCTAssertEqual(sortedItems[2].name, "Cheese") // low last
    }
    
    func testCombinedFiltering() {
        // Given
        let items = [
            createMockItem(name: "Milk", isCompleted: false, category: "dairy"),
            createMockItem(name: "Cheese", isCompleted: true, category: "dairy"),
            createMockItem(name: "Bread", isCompleted: false, category: "bakery")
        ]
        
        viewModel.items = items
        
        // When - Filter by category AND hide completed items
        viewModel.selectedCategory = "dairy"
        viewModel.showCompletedItems = false
        
        // Then - Should only show incomplete dairy items
        XCTAssertEqual(viewModel.filteredItems.count, 1, "Should show 1 incomplete dairy item")
        XCTAssertEqual(viewModel.filteredItems.first?.name, "Milk", "Should be the Milk item")
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
        XCTAssertNil(viewModel.errorMessage, "Should not have an error message")
    }
    
    private func createMockItem(name: String, isCompleted: Bool, category: String? = nil, priority: ListItem.Priority = .normal) -> ListItem {
        return ListItem(
            id: UUID().uuidString,
            name: name,
            note: nil,
            quantity: nil,
            priority: priority,
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

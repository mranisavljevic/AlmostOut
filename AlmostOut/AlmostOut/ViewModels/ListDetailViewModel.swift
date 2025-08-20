//
//  ListDetailViewModel.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/11/25.
//

import Combine
import SwiftUI

@MainActor
class ListDetailViewModel: ObservableObject {
    @Published var list: ShoppingList?
    @Published var items: [ListItem] = []
    @Published var filteredItems: [ListItem] = []
    @Published var searchText = ""
    @Published var selectedCategory: String?
    @Published var showCompletedItems = true
    @Published var sortOption: SortOption = .priority
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    enum SortOption: String, CaseIterable {
        case priority, name, dateAdded, category
        
        var displayName: String {
            switch self {
            case .priority: return "Priority"
            case .name: return "Name"
            case .dateAdded: return "Date Added"
            case .category: return "Category"
            }
        }
    }
    
    private let listId: String
    private let databaseService: DatabaseServiceProtocol
    private let authService: AuthServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(
        listId: String,
        databaseService: DatabaseServiceProtocol = FirestoreService(),
        authService: AuthServiceProtocol = FirebaseAuthService()
    ) {
        self.listId = listId
        self.databaseService = databaseService
        self.authService = authService
        setupItemsObserver()
        setupFiltering()
    }
    
    private func setupItemsObserver() {
        databaseService.observeListItems(for: listId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] items in
                    self?.items = items
                }
            )
            .store(in: &cancellables)
    }
    
    private func setupFiltering() {
        Publishers.CombineLatest4(
            $items,
            $searchText,
            $selectedCategory,
            $showCompletedItems
        )
        .map { [weak self] items, searchText, category, showCompleted in
            self?.filterAndSortItems(items, searchText: searchText, category: category, showCompleted: showCompleted) ?? []
        }
        .assign(to: \.filteredItems, on: self)
        .store(in: &cancellables)
    }
    
    private func filterAndSortItems(_ items: [ListItem], searchText: String, category: String?, showCompleted: Bool) -> [ListItem] {
        var filtered = items
        
        // Filter by completion status
        if !showCompleted {
            filtered = filtered.filter { !$0.isCompleted }
        }
        
        // Filter by category
        if let category = category {
            filtered = filtered.filter { $0.category?.name == category }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.note?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Sort items
        return filtered.sorted { item1, item2 in
            // Always show incomplete items first
            if item1.isCompleted != item2.isCompleted {
                return !item1.isCompleted && item2.isCompleted
            }
            
            switch sortOption {
            case .priority:
                return item1.priority.sortOrder < item2.priority.sortOrder
            case .name:
                return item1.name < item2.name
            case .dateAdded:
                return item1.createdAt > item2.createdAt
            case .category:
                let cat1 = item1.category?.name ?? "zzz"
                let cat2 = item2.category?.name ?? "zzz"
                return cat1 < cat2
            }
        }
    }
    
    func toggleItemCompletion(_ item: ListItem) async {
        guard let userId = authService.currentUser?.uid,
              let displayName = authService.currentUser?.displayName else { return }
        
        let updatedItem = ListItem(
            id: item.id,
            name: item.name,
            note: item.note,
            quantity: item.quantity,
            priority: item.priority,
            category: item.category,
            addedBy: item.addedBy,
            addedByName: item.addedByName,
            createdAt: item.createdAt,
            updatedAt: Date(),
            isCompleted: !item.isCompleted,
            completedBy: !item.isCompleted ? userId : nil,
            completedByName: !item.isCompleted ? displayName : nil,
            completedAt: !item.isCompleted ? Date() : nil,
            priceGuidance: item.priceGuidance,
            images: item.images,
            actualPrice: item.actualPrice,
            storeLocation: item.storeLocation
        )
        
        do {
            try await databaseService.updateItem(updatedItem, in: listId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteItem(_ item: ListItem) async {
        guard let itemId = item.id else { return }
        
        do {
            try await databaseService.deleteItem(id: itemId, from: listId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    var categories: [String] {
        Set(items.compactMap { $0.category?.name }).sorted()
    }
    
    var completionPercentage: Double {
        guard !items.isEmpty else { return 0 }
        let completedCount = items.filter { $0.isCompleted }.count
        return Double(completedCount) / Double(items.count)
    }
}

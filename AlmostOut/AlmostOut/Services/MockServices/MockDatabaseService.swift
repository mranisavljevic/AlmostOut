//
//  MockDatabaseService.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/11/25.
//


class MockDatabaseService: DatabaseServiceProtocol {
    private let listsSubject = CurrentValueSubject<[ShoppingList], Error>([])
    private let itemsSubject = CurrentValueSubject<[ListItem], Error>([])
    
    var mockLists: [ShoppingList] = []
    var mockItems: [ListItem] = []
    var shouldFailOperations = false
    
    func observeLists(for userId: String) -> AnyPublisher<[ShoppingList], Error> {
        listsSubject.send(mockLists)
        return listsSubject.eraseToAnyPublisher()
    }
    
    func observeListItems(for listId: String) -> AnyPublisher<[ListItem], Error> {
        let filteredItems = mockItems.filter { _ in true } // In real implementation, filter by listId
        itemsSubject.send(filteredItems)
        return itemsSubject.eraseToAnyPublisher()
    }
    
    func createList(_ list: ShoppingList) async throws -> String {
        if shouldFailOperations {
            throw NSError(domain: "MockError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Database error"])
        }
        
        let listId = UUID().uuidString
        var newList = list
        newList.id = listId
        mockLists.append(newList)
        listsSubject.send(mockLists)
        return listId
    }
    
    func updateList(_ list: ShoppingList) async throws {
        if shouldFailOperations {
            throw NSError(domain: "MockError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Database error"])
        }
        
        if let index = mockLists.firstIndex(where: { $0.id == list.id }) {
            mockLists[index] = list
            listsSubject.send(mockLists)
        }
    }
    
    func deleteList(id: String) async throws {
        if shouldFailOperations {
            throw NSError(domain: "MockError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Database error"])
        }
        
        mockLists.removeAll { $0.id == id }
        listsSubject.send(mockLists)
    }
    
    func addItem(_ item: ListItem, to listId: String) async throws -> String {
        if shouldFailOperations {
            throw NSError(domain: "MockError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Database error"])
        }
        
        let itemId = UUID().uuidString
        var newItem = item
        newItem.id = itemId
        mockItems.append(newItem)
        itemsSubject.send(mockItems)
        return itemId
    }
    
    func updateItem(_ item: ListItem, in listId: String) async throws {
        if shouldFailOperations {
            throw NSError(domain: "MockError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Database error"])
        }
        
        if let index = mockItems.firstIndex(where: { $0.id == item.id }) {
            mockItems[index] = item
            itemsSubject.send(mockItems)
        }
    }
    
    func deleteItem(id: String, from listId: String) async throws {
        if shouldFailOperations {
            throw NSError(domain: "MockError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Database error"])
        }
        
        mockItems.removeAll { $0.id == id }
        itemsSubject.send(mockItems)
    }
    
    func inviteUser(email: String, to listId: String, role: ShoppingList.ListMember.MemberRole) async throws {
        // Mock implementation
    }
    
    func acceptInvitation(id: String) async throws {
        // Mock implementation
    }
}
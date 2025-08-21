//
//  ListsViewModel.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/11/25.
//

import Combine
import SwiftUI

@MainActor
class ListsViewModel: ObservableObject {
    @Published var lists: [ShoppingList] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let databaseService: DatabaseServiceProtocol
    private let authService: AuthServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(
        databaseService: DatabaseServiceProtocol = FirestoreService(),
        authService: AuthServiceProtocol = FirebaseAuthService()
    ) {
        self.databaseService = databaseService
        self.authService = authService
        setupListsObserver()
    }
    
    private func setupListsObserver() {
        authService.authStatePublisher
            .compactMap { $0?.uid }
            .flatMap { [weak self] userId in
                self?.databaseService.observeLists(for: userId) ?? Empty().eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] lists in
                    self?.lists = lists // Already sorted by Firestore query
                }
            )
            .store(in: &cancellables)
    }
    
    func createList(name: String, description: String? = nil) async {
        guard let userId = authService.currentUser?.uid,
              let displayName = authService.currentUser?.displayName else { return }
        
        isLoading = true
        
        let memberInfo = ShoppingList.ListMember(
            role: .owner,
            joinedAt: Date(),
            displayName: displayName
        )
        
        let newList = ShoppingList(
            name: name,
            description: description,
            createdBy: userId,
            createdAt: Date(),
            updatedAt: Date(),
            memberIds: [userId],  // Array instead of object
            memberDetails: [userId: memberInfo],  // Details stored separately
            isArchived: false,
            totalItems: 0,
            completedItems: 0
        )
        
        do {
            _ = try await databaseService.createList(newList)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func deleteList(_ list: ShoppingList) async {
        guard let listId = list.id else { return }
        
        do {
            try await databaseService.deleteList(id: listId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

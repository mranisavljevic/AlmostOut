//
//  FirestoreService.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/11/25.
//

import Combine
import FirebaseFirestore
import Foundation

class FirestoreService: DatabaseServiceProtocol {
    private let db = Firestore.firestore()
    private var listListeners: [String: ListenerRegistration] = [:]
    private var itemListeners: [String: ListenerRegistration] = [:]
    
    func observeLists(for userId: String) -> AnyPublisher<[ShoppingList], Error> {
        let subject = PassthroughSubject<[ShoppingList], Error>()
        
        let listener = db.collection(FirebaseConstants.listsCollection)
            .whereField("members.\(userId)", isNotEqualTo: NSNull())
            .order(by: "updatedAt", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    subject.send(completion: .failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    subject.send([])
                    return
                }
                
                do {
                    let lists = try documents.compactMap { try $0.data(as: ShoppingList.self) }
                    subject.send(lists)
                } catch {
                    subject.send(completion: .failure(error))
                }
            }
        
        listListeners[userId] = listener
        
        return subject.eraseToAnyPublisher()
    }
    
    func observeListItems(for listId: String) -> AnyPublisher<[ListItem], Error> {
        let subject = PassthroughSubject<[ListItem], Error>()
        
        let listener = db.collection(FirebaseConstants.listsCollection)
            .document(listId)
            .collection(FirebaseConstants.itemsSubcollection)
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    subject.send(completion: .failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    subject.send([])
                    return
                }
                
                do {
                    let items = try documents.compactMap { try $0.data(as: ListItem.self) }
                    subject.send(items)
                } catch {
                    subject.send(completion: .failure(error))
                }
            }
        
        itemListeners[listId] = listener
        
        return subject.eraseToAnyPublisher()
    }
    
    func createList(_ list: ShoppingList) async throws -> String {
        let docRef = db.collection(FirebaseConstants.listsCollection).document()
        var newList = list
        newList.id = docRef.documentID
        
        try docRef.setData(from: newList)
        return docRef.documentID
    }
    
    func updateList(_ list: ShoppingList) async throws {
        guard let listId = list.id else {
            throw FirestoreError.missingDocumentID
        }
        
        let docRef = db.collection(FirebaseConstants.listsCollection).document(listId)
        try docRef.setData(from: list, merge: true)
    }
    
    func deleteList(id: String) async throws {
        let docRef = db.collection(FirebaseConstants.listsCollection).document(id)
        try await docRef.delete()
    }
    
    func addItem(_ item: ListItem, to listId: String) async throws -> String {
        let docRef = db.collection(FirebaseConstants.listsCollection)
            .document(listId)
            .collection(FirebaseConstants.itemsSubcollection)
            .document()
        
        var newItem = item
        newItem.id = docRef.documentID
        
        try docRef.setData(from: newItem)
        
        // Update list statistics
        try await updateListStatistics(listId: listId)
        
        return docRef.documentID
    }
    
    func updateItem(_ item: ListItem, in listId: String) async throws {
        guard let itemId = item.id else {
            throw FirestoreError.missingDocumentID
        }
        
        let docRef = db.collection(FirebaseConstants.listsCollection)
            .document(listId)
            .collection(FirebaseConstants.itemsSubcollection)
            .document(itemId)
        
        try docRef.setData(from: item, merge: true)
        
        // Update list statistics
        try await updateListStatistics(listId: listId)
    }
    
    func deleteItem(id: String, from listId: String) async throws {
        let docRef = db.collection(FirebaseConstants.listsCollection)
            .document(listId)
            .collection(FirebaseConstants.itemsSubcollection)
            .document(id)
        
        try await docRef.delete()
        
        // Update list statistics
        try await updateListStatistics(listId: listId)
    }
    
    private func updateListStatistics(listId: String) async throws {
        let itemsRef = db.collection(FirebaseConstants.listsCollection)
            .document(listId)
            .collection(FirebaseConstants.itemsSubcollection)
        
        let snapshot = try await itemsRef.getDocuments()
        let totalItems = snapshot.documents.count
        let completedItems = snapshot.documents.filter { doc in
            doc.data()["isCompleted"] as? Bool == true
        }.count
        
        let listRef = db.collection(FirebaseConstants.listsCollection).document(listId)
        try await listRef.updateData([
            "totalItems": totalItems,
            "completedItems": completedItems,
            "updatedAt": Timestamp()
        ])
    }
    
    func inviteUser(email: String, to listId: String, role: ShoppingList.ListMember.MemberRole) async throws {
        // Implementation for user invitations
        // This would create an invitation document and send notification
    }
    
    func acceptInvitation(id: String) async throws {
        // Implementation for accepting invitations
        // This would update the list members and delete the invitation
    }
}

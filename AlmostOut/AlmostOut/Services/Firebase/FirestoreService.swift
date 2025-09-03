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
    
    func observeList(id: String) -> AnyPublisher<ShoppingList?, Error> {
        let subject = PassthroughSubject<ShoppingList?, Error>()
        
        let listener = db.collection(FirebaseConstants.listsCollection)
            .document(id)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    subject.send(completion: .failure(error))
                    return
                }
                
                guard let document = snapshot, document.exists else {
                    subject.send(nil)
                    return
                }
                
                do {
                    let list = try document.data(as: ShoppingList.self)
                    subject.send(list)
                } catch {
                    subject.send(completion: .failure(error))
                }
            }
        
        return subject.eraseToAnyPublisher()
    }
    
    func observeLists(for userId: String) -> AnyPublisher<[ShoppingList], Error> {
            let subject = PassthroughSubject<[ShoppingList], Error>()
            
            // Updated query using array-contains
            let listener = db.collection(FirebaseConstants.listsCollection)
                .whereField("memberIds", arrayContains: userId)
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
    
    func addMemberToList(userId: String, memberInfo: ShoppingList.ListMember, to listId: String) async throws {
        let docRef = db.collection(FirebaseConstants.listsCollection).document(listId)
        
        try await docRef.updateData([
            "memberIds": FieldValue.arrayUnion([userId]),
            "memberDetails.\(userId)": [
                "role": memberInfo.role.rawValue,
                "joinedAt": memberInfo.joinedAt,
                "displayName": memberInfo.displayName
            ]
        ])
    }
    
    func removeMemberFromList(userId: String, from listId: String) async throws {
        let docRef = db.collection(FirebaseConstants.listsCollection).document(listId)
        
        try await docRef.updateData([
            "memberIds": FieldValue.arrayRemove([userId]),
            "memberDetails.\(userId)": FieldValue.delete()
        ])
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
    
    func createInvitation(_ invite: ListInvite) async throws -> String {
        let docRef = db.collection(FirebaseConstants.invitationsCollection).document()
        var newInvite = invite
        newInvite.id = docRef.documentID
        
        try docRef.setData(from: newInvite)
        return docRef.documentID
    }
    
    func observeIncomingInvitations(for userId: String, userEmail: String) -> AnyPublisher<[ListInvite], Error> {
        let subject = PassthroughSubject<[ListInvite], Error>()
        
        let listener = db.collection(FirebaseConstants.invitationsCollection)
            .whereField("status", isEqualTo: ListInvite.InviteStatus.pending.rawValue)
            .whereFilter(Filter.orFilter([
                Filter.whereField("invitedUserId", isEqualTo: userId),
                Filter.whereField("invitedEmail", isEqualTo: userEmail)
            ]))
            .order(by: "createdAt", descending: true)
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
                    let invites = try documents.compactMap { try $0.data(as: ListInvite.self) }
                    subject.send(invites)
                } catch {
                    subject.send(completion: .failure(error))
                }
            }
        
        return subject.eraseToAnyPublisher()
    }
    
    func observeOutgoingInvitations(for userId: String) -> AnyPublisher<[ListInvite], Error> {
        let subject = PassthroughSubject<[ListInvite], Error>()
        
        let listener = db.collection(FirebaseConstants.invitationsCollection)
            .whereField("invitedBy", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
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
                    let invites = try documents.compactMap { try $0.data(as: ListInvite.self) }
                    subject.send(invites)
                } catch {
                    subject.send(completion: .failure(error))
                }
            }
        
        return subject.eraseToAnyPublisher()
    }
    
    func updateInvitation(_ invite: ListInvite) async throws {
        guard let inviteId = invite.id else {
            throw FirestoreError.missingDocumentID
        }
        
        let docRef = db.collection(FirebaseConstants.invitationsCollection).document(inviteId)
        try docRef.setData(from: invite, merge: true)
    }
    
    func findListByShareCode(_ shareCode: String) async throws -> ShoppingList? {
        let snapshot = try await db.collection(FirebaseConstants.listsCollection)
            .whereField("shareSettings.allowSharing", isEqualTo: true)
            .getDocuments()
        
        // Since we removed the shareCode from ShoppingList, we need to find it via invitations
        // This is a temporary approach - in production we might store active share codes differently
        guard let document = snapshot.documents.first else {
            return nil
        }
        
        return try document.data(as: ShoppingList.self)
    }
    
    func findInvitationByShareCode(_ shareCode: String) async throws -> ListInvite? {
        let snapshot = try await db.collection(FirebaseConstants.invitationsCollection)
            .whereField("shareCode", isEqualTo: shareCode)
            .whereField("status", isEqualTo: ListInvite.InviteStatus.pending.rawValue)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = snapshot.documents.first else {
            return nil
        }
        
        return try document.data(as: ListInvite.self)
    }
}

enum FirestoreError: Error, LocalizedError {
    case missingDocumentID
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .missingDocumentID:
            return "Document ID is missing"
        case .invalidData:
            return "Invalid data format"
        }
    }
}

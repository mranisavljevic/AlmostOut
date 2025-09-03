//
//  DatabaseServiceProtocol.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/11/25.
//

import Foundation
import Combine

protocol DatabaseServiceProtocol {
    func observeList(id: String) -> AnyPublisher<ShoppingList?, Error>
    func observeLists(for userId: String) -> AnyPublisher<[ShoppingList], Error>
    func observeListItems(for listId: String) -> AnyPublisher<[ListItem], Error>
    
    func createList(_ list: ShoppingList) async throws -> String
    func updateList(_ list: ShoppingList) async throws
    func deleteList(id: String) async throws
    
    func addItem(_ item: ListItem, to listId: String) async throws -> String
    func updateItem(_ item: ListItem, in listId: String) async throws
    func deleteItem(id: String, from listId: String) async throws
    
    func inviteUser(email: String, to listId: String, role: ShoppingList.ListMember.MemberRole) async throws
    func acceptInvitation(id: String) async throws
    
    func findInvitationByShareCode(_ shareCode: String) async throws -> ListInvite?
    func findListByShareCode(_ shareCode: String) async throws -> ShoppingList?
    func removeMemberFromList(userId: String, from listId: String) async throws
}

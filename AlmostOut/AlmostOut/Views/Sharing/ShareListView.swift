//
//  ShareListView.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 9/3/25.
//

import SwiftUI

struct ShareListView: View {
    let list: ShoppingList
    @StateObject private var viewModel: ShareListViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(list: ShoppingList) {
        self.list = list
        self._viewModel = StateObject(wrappedValue: ShareListViewModel(list: list))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    listInfoSection
                    shareLinksSection
                    membersSection
                }
                .padding()
            }
            .navigationTitle("Share List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var listInfoSection: some View {
        HStack {
            Image(systemName: "list.bullet")
                .foregroundColor(.blue)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(list.name)
                    .font(.headline)
                if let description = list.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var shareLinksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Share Links")
                    .font(.headline)
                
                Spacer()
                
                Menu {
                    Button {
                        viewModel.createShareLink(role: .editor)
                    } label: {
                        Label("Create Editor Link", systemImage: "pencil")
                    }
                    
                    Button {
                        viewModel.createShareLink(role: .viewer)
                    } label: {
                        Label("Create Viewer Link", systemImage: "eye")
                    }
                } label: {
                    Label("New Link", systemImage: "plus")
                }
                .buttonStyle(BorderedButtonStyle())
            }
            
            if viewModel.shareLinks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "link")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text("No share links yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Create a link to invite others to join this list")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.shareLinks) { shareLink in
                        ShareLinkRowView(
                            shareLink: shareLink,
                            onCopy: {
                                viewModel.copyShareLink(shareLink)
                            },
                            onShare: {
                                viewModel.shareLink(shareLink)
                            },
                            onDelete: {
                                viewModel.deleteShareLink(shareLink)
                            }
                        )
                    }
                }
            }
        }
    }
    
    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Members (\(list.memberIds.count))")
                .font(.headline)
            
            LazyVStack(spacing: 8) {
                ForEach(Array(list.memberDetails.keys), id: \.self) { userId in
                    if let member = list.memberDetails[userId] {
                        MemberRowView(
                            member: member,
                            userId: userId,
                            isOwner: list.isUserOwner(userId),
                            canRemove: list.canUserManageMembers(viewModel.currentUserId) && !list.isUserOwner(userId),
                            onRemove: {
                                viewModel.removeMember(userId)
                            }
                        )
                    }
                }
            }
        }
    }
}

struct ShareLinkRowView: View {
    let shareLink: ListInvite
    let onCopy: () -> Void
    let onShare: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(shareLink.role.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("Code: \(shareLink.shareCode)")
                            .font(.caption)
                            .fontWeight(.light)
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text("Expires: \(shareLink.expiresAt, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if shareLink.isExpired {
                            Text("EXPIRED")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        } else {
                            Text("ACTIVE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            
            HStack {
                Button("Copy Link") {
                    onCopy()
                }
                .buttonStyle(BorderedButtonStyle())
                .controlSize(.small)
                
                Button("Share") {
                    onShare()
                }
                .buttonStyle(BorderedButtonStyle())
                .controlSize(.small)
                
                Spacer()
                
                Button("Delete") {
                    onDelete()
                }
                .buttonStyle(BorderedButtonStyle())
                .controlSize(.small)
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(shareLink.isExpired ? Color(.systemGray6) : Color(.systemBlue).opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(shareLink.isExpired ? Color.clear : Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
}

struct MemberRowView: View {
    let member: ShoppingList.ListMember
    let userId: String
    let isOwner: Bool
    let canRemove: Bool
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: isOwner ? "crown.fill" : "person.fill")
                .foregroundColor(isOwner ? .yellow : .gray)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(member.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(member.role.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if canRemove {
                Button {
                    onRemove()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

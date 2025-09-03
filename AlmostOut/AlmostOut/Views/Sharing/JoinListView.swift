//
//  JoinListView.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 9/3/25.
//

import SwiftUI

struct JoinListView: View {
    let shareCode: String
    @StateObject private var viewModel: JoinListViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(shareCode: String) {
        self.shareCode = shareCode
        self._viewModel = StateObject(wrappedValue: JoinListViewModel(shareCode: shareCode))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if viewModel.isLoading {
                    loadingView
                } else if let invite = viewModel.invitation, let list = viewModel.targetList {
                    inviteDetailsView(invite, list: list)
                } else if let errorMessage = viewModel.errorMessage {
                    errorView(errorMessage)
                }
            }
            .padding()
            .navigationTitle("Join List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Not Now") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await viewModel.loadInvitation()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading invitation...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private func inviteDetailsView(_ invite: ListInvite, list: ShoppingList) -> some View {
        VStack(spacing: 24) {
            // Invitation header
            VStack(spacing: 12) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                
                Text("You're invited to join")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(list.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
            }
            
            // Invitation details
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "person")
                        .foregroundColor(.secondary)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading) {
                        Text("Invited by")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(invite.invitedByName)
                            .font(.subheadline)
                    }
                    
                    Spacer()
                }
                
                HStack {
                    Image(systemName: "key")
                        .foregroundColor(.secondary)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading) {
                        Text("You'll join as")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(invite.role.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                }
                
                if let message = invite.message {
                    HStack {
                        Image(systemName: "message")
                            .foregroundColor(.secondary)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading) {
                            Text("Message")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(message)
                                .font(.subheadline)
                        }
                        
                        Spacer()
                    }
                }
                
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading) {
                        Text("Expires")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(invite.expiresAt, style: .date)
                            .font(.subheadline)
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Spacer()
            
            // Action buttons
            if invite.canBeAccepted {
                VStack(spacing: 12) {
                    Button {
                        Task {
                            await viewModel.joinList()
                        }
                    } label: {
                        HStack {
                            if viewModel.isJoining {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else {
                                Image(systemName: "checkmark")
                            }
                            Text("Join List")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.isJoining)
                    
                    Button {
                        Task {
                            await viewModel.declineInvitation()
                        }
                    } label: {
                        HStack {
                            if viewModel.isDeclining {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Text("No Thanks")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.isDeclining)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    
                    Text(invite.isExpired ? "This invitation has expired" : "This invitation is no longer valid")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Button("OK") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)
            
            Text("Unable to load invitation")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("OK") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
    }
}
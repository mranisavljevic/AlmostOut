//
//  ListsView.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/21/25.
//

import SwiftUI

struct ListsView: View {
    @StateObject private var viewModel = ListsViewModel()
    @State private var showingCreateList = false
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.lists.isEmpty {
                    EmptyListsView {
                        showingCreateList = true
                    }
                } else {
                    List {
                        ForEach(viewModel.lists) { list in
                            NavigationLink(destination: ListDetailView(listId: list.id ?? "")) {
                                ListRowView(list: list)
                            }
                        }
                        .onDelete(perform: deleteList)
                    }
                }
            }
            .navigationTitle("Shopping Lists")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateList = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateList) {
                CreateListView()
            }
            .refreshable {
                // Lists automatically refresh via real-time listeners
            }
        }
    }
    
    private func deleteList(at offsets: IndexSet) {
        for index in offsets {
            let list = viewModel.lists[index]
            Task {
                await viewModel.deleteList(list)
            }
        }
    }
}

#Preview("Lists View") {
    ListsView()
}

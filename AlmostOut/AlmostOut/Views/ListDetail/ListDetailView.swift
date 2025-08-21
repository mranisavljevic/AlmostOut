//
//  ListDetailView.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/21/25.
//

import SwiftUI

struct ListDetailView: View {
    let listId: String
    @StateObject private var viewModel: ListDetailViewModel
    @State private var showingAddItem = false
    @State private var showingFilters = false
    
    init(listId: String) {
        self.listId = listId
        self._viewModel = StateObject(wrappedValue: ListDetailViewModel(listId: listId))
    }
    
    var body: some View {
        Group {
            if viewModel.filteredItems.isEmpty {
                EmptyItemsView {
                    showingAddItem = true
                }
            } else {
                List {
                    ForEach(viewModel.filteredItems) { item in
                        ItemRowView(item: item) {
                            Task {
                                await viewModel.toggleItemCompletion(item)
                            }
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
            }
        }
        .navigationTitle("Items")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showingFilters = true
                } label: {
                    Image(systemName: "line.horizontal.3.decrease.circle")
                }
                
                Button {
                    showingAddItem = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddItemView(listId: listId)
        }
        .sheet(isPresented: $showingFilters) {
            FilterView(viewModel: viewModel)
        }
        .searchable(text: $viewModel.searchText, prompt: "Search items...")
    }
    
    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = viewModel.filteredItems[index]
            Task {
                await viewModel.deleteItem(item)
            }
        }
    }
}

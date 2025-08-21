//
//  MainTabView.swift
//  AlmostOut
//
//  Created by Miles Ranisavljevic on 8/21/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ListsView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Lists")
                }
                .tag(0)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
                .tag(1)
        }
    }
}

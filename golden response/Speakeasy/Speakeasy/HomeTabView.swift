//
//  HomeTabView.swift
//  speakEasy
//
//  Created by Shivani Verma on 13/12/25.
//

import SwiftUI

enum AppTab: Hashable {
    case home
    case projects
    case words
    case profile
}

struct HomeTabView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(selectedTab: $selectedTab)
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(AppTab.home)

            NavigationStack {
                ProjectsView()
            }
            .tabItem {
                Label("Projects", systemImage: "folder")
            }
            .tag(AppTab.projects)

            NavigationStack {
                WordBasketView()
            }
            .tabItem {
                Label("Words", systemImage: "book.closed")
            }
            .tag(AppTab.words)

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
            .tag(AppTab.profile)
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 8)
        }
    }
}

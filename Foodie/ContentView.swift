//
//  ContentView.swift
//  Foodie
//
//  Created by Jonathan Xu on 8/12/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var preferences = UserPreferences.shared
    @EnvironmentObject private var session: AppSession
    @State private var showingProfile = false

    var body: some View {
        TabView {
            NavigationStack {
                SimpleFoodLogView()
                    .navigationTitle("Food Log")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showingProfile = true
                            } label: {
                                Image(systemName: "person.circle.fill")
                                    .font(.title3)
                            }
                        }
                    }
            }
            .tabItem {
                Image(systemName: "mic.fill")
                Text("Log")
            }

            NavigationStack {
                GroceryCartView()
                    .navigationTitle("Groceries")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showingProfile = true
                            } label: {
                                Image(systemName: "person.circle.fill")
                                    .font(.title3)
                            }
                        }
                    }
            }
            .tabItem {
                Image(systemName: "cart.fill")
                Text("Cart")
            }
        }
        .environmentObject(preferences)
        .sheet(isPresented: $showingProfile) {
            NavigationStack {
                ProfileView()
                    .environmentObject(session)
                    .environmentObject(preferences)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Done") {
                                showingProfile = false
                            }
                        }
                    }
            }
        }
    }
}

#Preview {
    ContentView()
}

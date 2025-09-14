//
//  ContentView.swift
//  Foodie
//
//  Created by Jonathan Xu on 8/12/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                CoachView()
                    .navigationTitle("Chat")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                Text("Chat")
            }

            NavigationStack {
                MealPlanView()
                    .navigationTitle("Plan")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Image(systemName: "cart.fill")
                Text("Plan")
            }

            NavigationStack {
                FoodLogView()
                    .navigationTitle("Log")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Image(systemName: "camera.fill")
                Text("Log")
            }

            NavigationStack {
                ProfileView()
                    .navigationTitle("Profile")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Image(systemName: "person.fill")
                Text("Profile")
            }
        }
    }
}

#Preview {
    ContentView()
}

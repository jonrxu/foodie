//
//  FoodieApp.swift
//  Foodie
//
//  Created by Jonathan Xu on 8/12/25.
//

import SwiftUI

@main
struct FoodieApp: App {
    @StateObject private var session = AppSession.shared
    @StateObject private var preferences = UserPreferences.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .environmentObject(preferences)
        }
    }
}

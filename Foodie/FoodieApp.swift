//
//  FoodieApp.swift
//  Foodie
//
//  Created by Jonathan Xu on 8/12/25.
//

import SwiftUI

@main
struct FoodieApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Ensure Info.plist privacy strings exist; if not, devs will see system prompt failures.
                    // NSCameraUsageDescription, NSPhotoLibraryUsageDescription (if library is used)
                }
        }
    }
}

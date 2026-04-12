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
    @StateObject private var dexcomViewModel = DexcomConnectionViewModel.shared
    @StateObject private var mealFlowViewModel = PrototypeMealFlowViewModel.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .environmentObject(dexcomViewModel)
                .environmentObject(mealFlowViewModel)
                .task {
                    await dexcomViewModel.bootstrapIfNeeded()
                    await mealFlowViewModel.bootstrapIfNeeded()
                }
                .onOpenURL { url in
                    Task {
                        await dexcomViewModel.handleIncomingURL(url)
                    }
                }
        }
    }
}

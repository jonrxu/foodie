//
//  FoodieApp.swift
//  Foodie
//
//  Created by Jonathan Xu on 8/12/25.
//

import SwiftUI

@main
struct FoodieApp: App {
    @UIApplicationDelegateAdaptor(AgentNotificationAppDelegate.self) private var appDelegate
    @StateObject private var session = AppSession.shared
    @StateObject private var authViewModel = AuthViewModel.shared
    @StateObject private var dexcomViewModel = DexcomConnectionViewModel.shared
    @StateObject private var mealFlowViewModel = PrototypeMealFlowViewModel.shared
    @StateObject private var agentFeedViewModel = AgentFeedViewModel.shared
    @StateObject private var agentNotificationRouter = AgentNotificationRouter.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .environmentObject(authViewModel)
                .environmentObject(dexcomViewModel)
                .environmentObject(mealFlowViewModel)
                .environmentObject(agentFeedViewModel)
                .environmentObject(agentNotificationRouter)
                .preferredColorScheme(.light)
                .task {
                    await authViewModel.bootstrapIfNeeded()
                    if authViewModel.isAuthenticated {
                        await dexcomViewModel.bootstrapIfNeeded()
                        await mealFlowViewModel.bootstrapIfNeeded()
                        await agentFeedViewModel.bootstrapIfNeeded()
                    }
                }
                .onOpenURL { url in
                    Task {
                        await dexcomViewModel.handleIncomingURL(url)
                    }
                }
        }
    }
}

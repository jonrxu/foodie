//
//  RootView.swift
//  Foodie
//
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var dexcomViewModel: DexcomConnectionViewModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        PrototypeAppShellView()
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    Task {
                        await dexcomViewModel.refreshConnectionStatus()
                    }
                }
            }
    }
}

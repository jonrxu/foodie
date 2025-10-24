//
//  RootView.swift
//  Foodie
//
//

import SwiftUI

struct RootView: View {
    @StateObject private var session = AppSession.shared

    var body: some View {
        ContentView()
            .environmentObject(session)
            .fullScreenCover(isPresented: Binding(
                get: { session.isOnboardingPresented },
                set: { newValue in
                    if newValue == false { session.cancelOnboarding() }
                }
            )) {
                SimpleOnboardingView()
                    .environmentObject(session)
            }
            .onAppear {
                if session.profile?.hasCompletedOnboarding == false {
                    session.startOnboarding()
                }
            }
    }
}



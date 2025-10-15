//
//  RootView.swift
//  Foodie
//
//  Created by AI Assistant.
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
                OnboardingFlowView(profile: session.profile ?? UserProfile())
                    .environmentObject(session)
            }
            .onAppear {
                if session.profile?.hasCompletedOnboarding == false {
                    session.startOnboarding()
                }
            }
    }
}



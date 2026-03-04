//
//  MockupsCommon.swift
//  Foodie
//
//  Shared UI helpers for demo-only mock screens.
//

import SwiftUI

struct AdviceLine: View {
    let systemImage: String
    let color: Color
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 18)
                .padding(.top, 2)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

extension View {
    /// Hides the app TabView tab bar for full-screen demo mockups (iOS 16+).
    @ViewBuilder
    func mockupsFullscreen() -> some View {
        if #available(iOS 16.0, *) {
            self
                .toolbar(.hidden, for: .tabBar)
                .toolbarBackground(.hidden, for: .tabBar)
        } else {
            self
        }
    }
}


//
//  ProfileView.swift
//  Foodie
//
//  Created by AI Assistant.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        Form {
            Section("Account") {
                HStack {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(AppTheme.primary)
                    VStack(alignment: .leading) {
                        Text("Your Name").font(.headline)
                        Text("Premium • Streak 7").foregroundStyle(.secondary)
                    }
                }
            }

            Section("Preferences") {
                NavigationLink { Text("Dietary Preferences") } label: {
                    Label("Dietary Preferences", systemImage: "leaf.fill")
                }
                NavigationLink { Text("Cuisines") } label: {
                    Label("Favorite Cuisines", systemImage: "globe")
                }
                NavigationLink { Text("Budget & Time") } label: {
                    Label("Budget & Time", systemImage: "clock")
                }
            }

            Section("Settings") {
                NavigationLink { Text("Notifications") } label: {
                    Label("Notifications", systemImage: "bell.fill")
                }
                NavigationLink { ApiKeySettingsView() } label: {
                    Label("OpenAI API Key", systemImage: "key.fill")
                }
            }
        }
        .scrollContentBackground(.automatic)
        .background(AppTheme.background)
    }
}

#Preview {
    NavigationStack { ProfileView() }
}



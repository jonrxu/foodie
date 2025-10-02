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
                NavigationLink { DietaryPreferencesView() } label: {
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

struct DietaryPreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text: String = UserPreferencesStore.shared.loadDietaryPreferences()
    @State private var savedText: String = UserPreferencesStore.shared.loadDietaryPreferences()

    private var isDirty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines) != savedText
    }

    var body: some View {
        Form {
            Section("Let Foodie know your dietary needs") {
                TextEditor(text: $text)
                    .frame(minHeight: 180)
                    .textInputAutocapitalization(.sentences)
                Text("Examples: vegetarian weekdays, low sodium, allergic to peanuts, hate mushrooms.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Dietary Preferences")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    UserPreferencesStore.shared.saveDietaryPreferences(trimmed)
                    savedText = trimmed
                    dismiss()
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !isDirty)
            }
            ToolbarItem(placement: .bottomBar) {
                Button(role: .destructive) {
                    text = ""
                    UserPreferencesStore.shared.clearDietaryPreferences()
                    savedText = ""
                } label: {
                    Label("Clear", systemImage: "trash")
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}



//
//  ProfileView.swift
//  Foodie
//
//  Created by AI Assistant.
//

import SwiftUI

struct ProfileView: View {
    @State private var displayName: String = UserPreferencesStore.shared.loadDisplayName()

    var body: some View {
        Form {
            Section("Account") {
                HStack {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(AppTheme.primary)
                    VStack(alignment: .leading) {
                        TextField("Your Name", text: $displayName)
                            .font(.headline)
                            .textInputAutocapitalization(.words)
                            .disableAutocorrection(true)
                        Text("Premium • Streak 7").foregroundStyle(.secondary)
                    }
                }
                .onDisappear {
                    UserPreferencesStore.shared.saveDisplayName(displayName)
                }
            }

            Section("Preferences") {
                NavigationLink { DietaryPreferencesView() } label: {
                    Label("Dietary Preferences", systemImage: "leaf.fill")
                }
                NavigationLink { FavoriteCuisinesView() } label: {
                    Label("Favorite Cuisines", systemImage: "globe")
                }
                NavigationLink { BudgetTimePreferencesView() } label: {
                    Label("Budget & Time", systemImage: "clock")
                }
            }

            Section("Settings") {
                NavigationLink { NotificationsView() } label: {
                    Label("Notifications", systemImage: "bell.fill")
                }
                NavigationLink { ApiKeySettingsView() } label: {
                    Label("OpenAI API Key", systemImage: "key.fill")
                }
            }
        }
        .scrollContentBackground(.automatic)
        .background(AppTheme.background)
        .onDisappear {
            UserPreferencesStore.shared.saveDisplayName(displayName)
        }
    }
}

#Preview {
    NavigationStack { ProfileView() }
}

struct NotificationsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No notifications right now")
                .font(.title3).bold()
            Text("Stay tuned—Foodie will let you know when important updates arrive.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DietaryPreferencesView: View {
    var body: some View {
        PreferenceEditorScreen(
            title: "Dietary Preferences",
            hint: "Examples: vegetarian weekdays, low sodium, allergic to peanuts, hate mushrooms.",
            initialValue: UserPreferencesStore.shared.loadDietaryPreferences(),
            onSave: { value in UserPreferencesStore.shared.saveDietaryPreferences(value) },
            onClear: { UserPreferencesStore.shared.clearDietaryPreferences() }
        )
    }
}

struct FavoriteCuisinesView: View {
    var body: some View {
        PreferenceEditorScreen(
            title: "Favorite Cuisines",
            hint: "Examples: Thai takeout Fridays, love Mediterranean lunches, open to Latin flavors.",
            initialValue: UserPreferencesStore.shared.loadFavoriteCuisines(),
            onSave: { value in UserPreferencesStore.shared.saveFavoriteCuisines(value) },
            onClear: { UserPreferencesStore.shared.clearFavoriteCuisines() }
        )
    }
}

struct BudgetTimePreferencesView: View {
    var body: some View {
        PreferenceEditorScreen(
            title: "Budget & Time",
            hint: "Examples: grocery budget $60/week, 20-minute dinners, weekend meal prep ok.",
            initialValue: UserPreferencesStore.shared.loadBudgetPreferences(),
            onSave: { value in UserPreferencesStore.shared.saveBudgetPreferences(value) },
            onClear: { UserPreferencesStore.shared.clearBudgetPreferences() }
        )
    }
}

private struct PreferenceEditorScreen: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let hint: String
    let initialValue: String
    let onSave: (String) -> Void
    let onClear: () -> Void

    @State private var text: String = ""
    @State private var savedText: String = ""

    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isDirty: Bool { trimmed != savedText }

    var body: some View {
        Form {
            Section("Tell Foodie what to remember") {
                TextEditor(text: $text)
                    .frame(minHeight: 200)
                    .textInputAutocapitalization(.sentences)
                Text(hint)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    let value = trimmed
                    onSave(value)
                    savedText = value
                    dismiss()
                }
                .disabled(trimmed.isEmpty || !isDirty)
            }
            ToolbarItem(placement: .bottomBar) {
                Button(role: .destructive) {
                    onClear()
                    text = ""
                    savedText = ""
                } label: {
                    Label("Clear", systemImage: "trash")
                }
                .disabled(trimmed.isEmpty)
            }
        }
        .onAppear {
            text = initialValue
            savedText = initialValue
        }
    }
}



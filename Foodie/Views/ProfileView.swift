//
//  ProfileView.swift
//  Foodie
//
//  Created by AI Assistant.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var preferences: UserPreferences
    @State private var displayName: String = ""

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
                        Text("Beta • Joined \(joinedDateString)")
                            .foregroundStyle(.secondary)
                    }
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
        .onAppear {
            displayName = UserPreferencesStore.shared.loadDisplayName()
        }
        .onDisappear {
            UserPreferencesStore.shared.saveDisplayName(displayName)
        }
    }

    private var joinedDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: preferences.joinedDate)
    }
}

#Preview {
    NavigationStack { ProfileView().environmentObject(UserPreferences.shared) }
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
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var preferences: UserPreferences
    @State private var text: String = ""
    @State private var savedText: String = ""
    @State private var calorieGoalString: String = ""
    @State private var savedCalorieGoal: Int = 0
    @FocusState private var goalFieldFocused: Bool

    private var trimmedText: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isDirty: Bool {
        trimmedText != savedText || (Int(calorieGoalString) ?? savedCalorieGoal) != savedCalorieGoal
    }

    var body: some View {
        Form {
            Section("Daily calorie target") {
                HStack {
                    Label("Calorie Goal", systemImage: "flame")
                    Spacer()
                    TextField("kcal", text: $calorieGoalString)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 90)
                        .focused($goalFieldFocused)
                }
            }

            Section("Tell Foodie about your preferences") {
                TextEditor(text: $text)
                    .frame(minHeight: 200)
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
                    let trimmed = trimmedText
                    UserPreferencesStore.shared.saveDietaryPreferences(trimmed)
                    savedText = trimmed

                    if let value = Int(calorieGoalString), value > 0 {
                        preferences.dailyCalorieGoal = value
                        savedCalorieGoal = value
                    }

                    dismiss()
                }
                .disabled(!isDirty || (trimmedText.isEmpty && calorieGoalString.isEmpty))
            }
            ToolbarItem(placement: .bottomBar) {
                Button(role: .destructive) {
                    text = ""
                    savedText = ""
                    UserPreferencesStore.shared.clearDietaryPreferences()
                } label: {
                    Label("Clear Preferences", systemImage: "trash")
                }
                .disabled(trimmedText.isEmpty)
            }
            ToolbarItemGroup(placement: .keyboard) {
                if goalFieldFocused {
                    Spacer()
                    Button("Done") { goalFieldFocused = false }
                }
            }
        }
        .onAppear {
            let stored = UserPreferencesStore.shared.loadDietaryPreferences()
            text = stored
            savedText = stored

            let goal = preferences.dailyCalorieGoal
            calorieGoalString = "\(goal)"
            savedCalorieGoal = goal
        }
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



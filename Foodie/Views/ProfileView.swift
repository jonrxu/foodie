//
//  ProfileView.swift
//  Foodie
//
//  Created by AI Assistant.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var preferences: UserPreferences

    @State private var showingEdit = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                profileSummary
                preferencesSection
                settingsSection
            }
            .padding(.vertical, 24)
        }
        .safeAreaInset(edge: .bottom) { bottomActions }
        .background(AppTheme.background)
        .sheet(isPresented: $showingEdit) {
            OnboardingFlowView()
                .environmentObject(session)
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.primary)

            VStack(alignment: .leading, spacing: 4) {
                Text(displayName.ifEmpty("Welcome"))
                    .font(.title3).bold()
                Text("Joined \(joinedDateString)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let email = session.profile?.email, !email.isEmpty {
                    Text(email)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var profileSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your focus")
                .font(.headline)

            SummaryRow(label: "Dietary style", value: session.profile?.dietarySummary.ifEmpty("Let’s choose one") ?? "Let’s choose one")
            SummaryRow(label: "Allergies", value: session.profile?.allergySummary.ifEmpty("No allergies noted") ?? "No allergies noted")
            SummaryRow(label: "Goals", value: session.profile?.goalsSummary.ifEmpty("Set your goals") ?? "Set your goals")
            if let calorieGoal = session.profile?.dailyCalorieGoal ?? preferences.dailyCalorieGoal.nonZero {
                SummaryRow(label: "Daily calories", value: "\(calorieGoal) kcal")
            }
        }
        .padding(.horizontal, 24)
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lifestyle notes")
                .font(.headline)

            SummaryRow(label: "Favorite cuisines", value: session.profile?.favoriteCuisinesSummary.ifEmpty("Add cuisines you love") ?? "Add cuisines you love")
            SummaryRow(label: "Budget & time", value: session.profile?.lifestyleSummary.ifEmpty("Share budget or prep notes") ?? "Share budget or prep notes")
        }
        .padding(.horizontal, 24)
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.headline)

            NavigationLink {
                NotificationsView()
            } label: {
                SettingRow(icon: "bell.fill", title: "Notifications")
            }

            NavigationLink {
                ApiKeySettingsView()
            } label: {
                SettingRow(icon: "key.fill", title: "OpenAI API Key")
            }
        }
        .padding(.horizontal, 24)
    }

    private var bottomActions: some View {
        VStack(spacing: 12) {
            Button {
                showingEdit = true
            } label: {
                Text("Edit profile")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            Button(role: .destructive) {
                session.signOut()
            } label: {
                Text("Sign out")
                    .font(.body)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 24)
        .background(.ultraThinMaterial)
    }

    private var displayName: String {
        session.profile?.displayName ?? UserPreferencesStore.shared.loadDisplayName()
    }

    private var joinedDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: session.profile?.joinedDate ?? preferences.joinedDate)
    }
}

private struct SummaryRow: View {
    let label: String?
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let label {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.body)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct SettingRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppTheme.primary)
            Text(title)
                .font(.body)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct NotificationsView: View {
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

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(AppSession.shared)
            .environmentObject(UserPreferences.shared)
    }
}

private extension Int {
    var nonZero: Int? { self == 0 ? nil : self }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : self
    }
}

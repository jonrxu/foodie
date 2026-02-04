//
//  FoodLoggingMockView.swift
//  Foodie
//
//  Step 2 mock: multi-modal food logging (visuals only).
//

import SwiftUI

struct FoodLoggingMockView: View {
    @State private var showingMockAlert = false
    @State private var lastTapped: String = "Option"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                heroHeader
                entryOptions
                recentMock
            }
            .padding()
        }
        .background(AppTheme.background)
        .navigationTitle("Log Your Meal")
        .navigationBarTitleDisplayMode(.inline)
        .mockupsFullscreen()
        .alert("Mock only", isPresented: $showingMockAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("\(lastTapped) is a demo-only button right now.")
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What did you eat?")
                .font(.title).bold()
            Text("Choose how you want to log — voice, photo, or text.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var entryOptions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Log options")
                .font(.headline)

            let columns = [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ]

            LazyVGrid(columns: columns, spacing: 12) {
                MockOptionCard(
                    title: "Voice",
                    subtitle: "Fastest",
                    systemImage: "mic.fill",
                    tint: AppTheme.primary
                ) {
                    tap("Voice log")
                }

                MockOptionCard(
                    title: "Photo",
                    subtitle: "Snap a plate",
                    systemImage: "camera.fill",
                    tint: .orange
                ) {
                    tap("Photo log")
                }

                MockOptionCard(
                    title: "Text",
                    subtitle: "Type it",
                    systemImage: "text.bubble.fill",
                    tint: .green
                ) {
                    tap("Text log")
                }
            }

            Button {
                tap("Start voice")
            } label: {
                Label("Start voice log", systemImage: "waveform")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var recentMock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent logs")
                .font(.headline)

            VStack(spacing: 10) {
                MockLogRow(title: "Greek yogurt + berries", subtitle: "Breakfast", badge: "Done")
                MockLogRow(title: "Chicken burrito bowl", subtitle: "Lunch", badge: "Done")
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func tap(_ name: String) {
        lastTapped = name
        showingMockAlert = true
    }
}

private struct MockOptionCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(tint.opacity(0.12))
                        .frame(height: 44)
                    Image(systemName: systemImage)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(tint)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline).bold()
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct MockLogRow: View {
    let title: String
    let subtitle: String
    let badge: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline).bold()
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(badge)
                .font(.caption).bold()
                .foregroundStyle(.white)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(
                    LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primary.opacity(0.65)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
        }
        .padding(12)
        .background(Color(uiColor: .tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        FoodLoggingMockView()
    }
}


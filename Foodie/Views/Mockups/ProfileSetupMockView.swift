//
//  ProfileSetupMockView.swift
//  Foodie
//
//  Mockup: simplified onboarding profile setup.
//

import SwiftUI

struct ProfileSetupMockView: View {
    @Environment(\.dismiss) private var dismiss

    let onContinue: (() -> Void)?
    let allowTapToDismiss: Bool

    @State private var selectedDiets: Set<String> = ["No red meat"]
    @State private var selectedDietNeeds: Set<String> = ["Low sodium"]
    @State private var selectedActivity: ActivityPreset = .light

    private let dietOptions = ["Vegan", "Vegetarian", "No red meat", "No pork"]
    private let dietNeedOptions = ["Low sodium", "Kidney disease", "Blood thinners", "High cholesterol"]

    init(onContinue: (() -> Void)? = nil, allowTapToDismiss: Bool = true) {
        self.onContinue = onContinue
        self.allowTapToDismiss = allowTapToDismiss
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                mockupBackground
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    topHeader
                        .contentShape(Rectangle())
                        .onTapGesture {
                            handleTapDismiss()
                        }

                    Spacer(minLength: 14)

                    profileCard
                        .contentShape(Rectangle())
                        .onTapGesture {
                            handleTapDismiss()
                        }

                    Spacer(minLength: 16)

                    HStack {
                        Spacer()
                        Button {
                            handleContinue()
                        } label: {
                            Text("Continue")
                                .font(.headline.weight(.semibold))
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .foregroundStyle(.white)
                                .background(AppTheme.primary)
                                .clipShape(Capsule())
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 62)
                .padding(.bottom, 24)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .mockupsFullscreen()
        .navigationBarBackButtonHidden(true)
    }

    private var topHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Set up your profile")
                .font(.system(size: 33, weight: .bold, design: .rounded))
            Text("Step 1 of 3 • Tell us about your food habits")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Diet preferences")
                    .font(.headline.weight(.semibold))
                flowDietChips
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Diet needs")
                    .font(.headline.weight(.semibold))
                flowDietNeedsChips
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Activity level")
                    .font(.headline.weight(.semibold))

                ForEach(ActivityPreset.allCases, id: \.self) { option in
                    Button {
                        selectedActivity = option
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: selectedActivity == option ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedActivity == option ? AppTheme.primary : .secondary)
                                .padding(.top, 2)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(option.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(option.subtitle)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(selectedActivity == option ? AppTheme.primary.opacity(0.12) : Color(uiColor: .tertiarySystemFill))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(.white.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.blue.opacity(0.12), lineWidth: 1)
        )
    }

    private var flowDietChips: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(dietOptions, id: \.self) { option in
                ChoicePill(title: option, isSelected: selectedDiets.contains(option)) {
                    toggleDiet(option)
                }
            }
        }
    }

    private var flowDietNeedsChips: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(dietNeedOptions, id: \.self) { option in
                ChoicePill(title: option, isSelected: selectedDietNeeds.contains(option)) {
                    toggleDietNeed(option)
                }
            }
        }
    }

    private func toggleDiet(_ option: String) {
        if selectedDiets.contains(option) {
            selectedDiets.remove(option)
        } else {
            selectedDiets.insert(option)
        }
    }

    private func toggleDietNeed(_ option: String) {
        if selectedDietNeeds.contains(option) {
            selectedDietNeeds.remove(option)
        } else {
            selectedDietNeeds.insert(option)
        }
    }

    private func handleContinue() {
        if let onContinue {
            onContinue()
        } else {
            dismiss()
        }
    }

    private func handleTapDismiss() {
        guard allowTapToDismiss else { return }
        dismiss()
    }

    private var mockupBackground: some View {
        ZStack {
            Color.white

            LinearGradient(
                colors: [
                    .white,
                    .white,
                    Color.blue.opacity(0.003),
                    Color.blue.opacity(0.012)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [Color.blue.opacity(0.012), Color.blue.opacity(0.0)],
                center: UnitPoint(x: 0.5, y: 0.8),
                startRadius: 60,
                endRadius: 520
            )
        }
    }
}

private enum ActivityPreset: CaseIterable {
    case low
    case light
    case active
    case veryActive

    var title: String {
        switch self {
        case .low: return "Sedentary/Not Very Active"
        case .light: return "Lightly Active"
        case .active: return "Active"
        case .veryActive: return "Very Active"
        }
    }

    var subtitle: String {
        switch self {
        case .low: return "Mostly sitting during the day"
        case .light: return "On your feet for part of the day"
        case .active: return "Regular movement most of the day"
        case .veryActive: return "Heavy physical activity most of the day"
        }
    }
}

private struct ChoicePill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 10)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isSelected ? AppTheme.primary : Color(uiColor: .tertiarySystemFill))
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ProfileSetupMockView()
    }
}

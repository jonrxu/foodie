//
//  DemoAppFlowView.swift
//  Foodie
//
//  Integrated live-demo flow: onboarding -> dashboard -> core journeys.
//

import SwiftUI

struct DemoAppFlowView: View {
    @State private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                DemoHomeView(
                    onResetToOnboarding: {
                        withAnimation(.easeInOut) {
                            hasCompletedOnboarding = false
                        }
                    }
                )
            } else {
                DemoOnboardingFlowView {
                    withAnimation(.easeInOut) {
                        hasCompletedOnboarding = true
                    }
                }
            }
        }
    }
}

private struct DemoOnboardingFlowView: View {
    let onComplete: () -> Void

    @State private var stepIndex = 0

    var body: some View {
        Group {
            switch stepIndex {
            case 0:
                ProfileSetupMockView(
                    onContinue: { stepIndex = 1 },
                    allowTapToDismiss: false
                )
            case 1:
                DiabetesGoalsOnboardingStep(
                    onBack: { stepIndex = 0 },
                    onContinue: { stepIndex = 2 }
                )
            default:
                SupportPreferencesOnboardingStep(
                    onBack: { stepIndex = 1 },
                    onContinue: onComplete
                )
            }
        }
    }
}

private struct DiabetesGoalsOnboardingStep: View {
    let onBack: () -> Void
    let onContinue: () -> Void

    @State private var selectedGoals: Set<String> = ["Reduce spikes"]
    @State private var usesCGM = true
    @State private var wantsMedicationReminders = true

    private let goals = [
        "Reduce spikes",
        "Keep glucose steady",
        "Heart health",
        "Weight goals"
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                DemoPageBackground()
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Care goals")
                            .font(.system(size: 33, weight: .bold, design: .rounded))
                        Text("Step 2 of 3 • Tell us your diabetes priorities")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 14)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("What matters most right now?")
                            .font(.headline.weight(.semibold))

                        LazyVGrid(
                            columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                            spacing: 10
                        ) {
                            ForEach(goals, id: \.self) { goal in
                                DemoChoicePill(
                                    title: goal,
                                    isSelected: selectedGoals.contains(goal),
                                    action: {
                                        if selectedGoals.contains(goal) {
                                            selectedGoals.remove(goal)
                                        } else {
                                            selectedGoals.insert(goal)
                                        }
                                    }
                                )
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Do you use a CGM?")
                                .font(.headline.weight(.semibold))
                            HStack(spacing: 10) {
                                DemoChoicePill(
                                    title: "Yes",
                                    isSelected: usesCGM,
                                    action: { usesCGM = true }
                                )
                                DemoChoicePill(
                                    title: "No",
                                    isSelected: !usesCGM,
                                    action: { usesCGM = false }
                                )
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Medication reminders")
                                .font(.headline.weight(.semibold))
                            HStack(spacing: 10) {
                                DemoChoicePill(
                                    title: "On",
                                    isSelected: wantsMedicationReminders,
                                    action: { wantsMedicationReminders = true }
                                )
                                DemoChoicePill(
                                    title: "Off",
                                    isSelected: !wantsMedicationReminders,
                                    action: { wantsMedicationReminders = false }
                                )
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

                    Spacer(minLength: 16)

                    HStack(spacing: 10) {
                        Button(action: onBack) {
                            Text("Back")
                                .font(.headline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(uiColor: .tertiarySystemFill))
                                .foregroundStyle(.primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Button(action: onContinue) {
                            Text("Continue")
                                .font(.headline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(AppTheme.primary)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
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
}

private struct SupportPreferencesOnboardingStep: View {
    let onBack: () -> Void
    let onContinue: () -> Void

    @State private var selectedSupports: Set<String> = ["Meal reminders", "Grocery reminders"]

    private let supportOptions = [
        "Meal reminders",
        "Grocery reminders",
        "CGM check-ins",
        "Weekly summary"
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                DemoPageBackground()
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Daily support")
                            .font(.system(size: 33, weight: .bold, design: .rounded))
                        Text("Step 3 of 3 • Choose support you want")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 14)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Pick what you want us to help with")
                            .font(.headline.weight(.semibold))

                        LazyVGrid(
                            columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                            spacing: 10
                        ) {
                            ForEach(supportOptions, id: \.self) { option in
                                DemoChoicePill(
                                    title: option,
                                    isSelected: selectedSupports.contains(option),
                                    action: {
                                        if selectedSupports.contains(option) {
                                            selectedSupports.remove(option)
                                        } else {
                                            selectedSupports.insert(option)
                                        }
                                    }
                                )
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("What happens next")
                                .font(.headline.weight(.semibold))
                            Text("You can log meals, track glucose trends, and order groceries in one flow")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(16)
                    .background(.white.opacity(0.96))
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.blue.opacity(0.12), lineWidth: 1)
                    )

                    Spacer(minLength: 16)

                    HStack(spacing: 10) {
                        Button(action: onBack) {
                            Text("Back")
                                .font(.headline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(uiColor: .tertiarySystemFill))
                                .foregroundStyle(.primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Button(action: onContinue) {
                            Text("Go to dashboard")
                                .font(.headline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(AppTheme.primary)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
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
}

private struct DemoHomeView: View {
    let onResetToOnboarding: () -> Void

    private enum Destination: Hashable {
        case selectMeals
        case foodLog
        case plateFeedback
        case cgmData
        case groceries
    }

    @State private var path: [Destination] = []

    var body: some View {
        NavigationStack(path: $path) {
            GeometryReader { geo in
                ZStack {
                    DemoPageBackground()
                        .ignoresSafeArea()

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Home")
                                    .font(.system(size: 33, weight: .bold, design: .rounded))
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        onResetToOnboarding()
                                    }
                                Text("Choose what you want to do next")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }

                            Button {
                                path.append(.groceries)
                            } label: {
                                HStack(alignment: .center, spacing: 12) {
                                    Image(systemName: "bell.badge.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(.orange)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Order groceries")
                                            .font(.headline.weight(.semibold))
                                            .foregroundStyle(.primary)
                                        Text("Your weekly cart is ready to review")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.footnote.weight(.bold))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(14)
                                .background(.white.opacity(0.96))
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(Color.orange.opacity(0.24), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)

                            LazyVGrid(
                                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                                spacing: 12
                            ) {
                                DashboardActionCard(
                                    title: "Select meals",
                                    subtitle: "Pick diabetes-friendly options",
                                    icon: "fork.knife",
                                    tint: .green
                                ) {
                                    path.append(.selectMeals)
                                }

                                DashboardActionCard(
                                    title: "Log food",
                                    subtitle: "Voice, photo, barcode, or text",
                                    icon: "camera.fill",
                                    tint: .blue
                                ) {
                                    path.append(.foodLog)
                                }

                                DashboardActionCard(
                                    title: "See CGM data",
                                    subtitle: "Simple weekly trend and goal",
                                    icon: "waveform.path.ecg",
                                    tint: .teal
                                ) {
                                    path.append(.cgmData)
                                }

                                DashboardActionCard(
                                    title: "Review cart",
                                    subtitle: "Adjust items before checkout",
                                    icon: "cart.fill",
                                    tint: .indigo
                                ) {
                                    path.append(.groceries)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 62)
                        .padding(.bottom, 24)
                        .frame(width: geo.size.width, alignment: .topLeading)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .mockupsFullscreen()
            .navigationBarBackButtonHidden(true)
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .selectMeals:
                    DinnerMealSelectionMockView()
                case .foodLog:
                    FoodLoggingMockView(
                        onModeSelected: { mode in
                            if mode == .takePhoto {
                                path.append(.plateFeedback)
                            }
                        }
                    )
                case .plateFeedback:
                    PlateFeedbackMockView()
                case .cgmData:
                    WeeklyGlucoseOverviewMockView(
                        onPlanMealsForNextWeek: {
                            path.append(.selectMeals)
                        }
                    )
                case .groceries:
                    ShoppingCartMockView()
                }
            }
        }
    }
}

private struct DashboardActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tint.opacity(0.16))
                        .frame(width: 42, height: 42)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(tint)
                }

                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(.white.opacity(0.96))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(tint.opacity(0.22), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct DemoChoicePill: View {
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
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isSelected ? AppTheme.primary : Color(uiColor: .tertiarySystemFill))
                )
        }
        .buttonStyle(.plain)
    }
}

private struct DemoPageBackground: View {
    var body: some View {
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

#Preview {
    DemoAppFlowView()
}

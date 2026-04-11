//
//  PrototypeAppShellView.swift
//  Foodie
//
//  Session-driven prototype shell built on top of the current mock-backed flows.
//

import SwiftUI

struct PrototypeAppShellView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        Group {
            if session.isOnboardingPresented {
                PrototypeOnboardingFlowView { dietPrefs, careGoals, supports in
                    Task {
                        if let response = try? await BackendClient.shared.registerUser(
                            name: "",
                            dietPreferences: dietPrefs,
                            careGoals: careGoals,
                            supportPreferences: supports
                        ) {
                            BackendClient.saveUserID(response.id)
                        }
                        session.completeOnboarding()
                    }
                }
            } else {
                PrototypeHomeView(
                    onResetToOnboarding: {
                        session.startOnboarding()
                    }
                )
            }
        }
    }
}

private struct PrototypeOnboardingFlowView: View {
    let onComplete: ([String], [String], [String]) -> Void

    @State private var stepIndex = 0
    @State private var collectedDietPrefs: [String] = []
    @State private var collectedCareGoals: [String] = []

    var body: some View {
        Group {
            switch stepIndex {
            case 0:
                ProfileSetupMockView(
                    onContinue: { prefs in
                        collectedDietPrefs = prefs
                        stepIndex = 1
                    },
                    allowTapToDismiss: false
                )
            case 1:
                PrototypeCareGoalsStep(
                    onBack: { stepIndex = 0 },
                    onContinue: { goals in
                        collectedCareGoals = goals
                        stepIndex = 2
                    }
                )
            default:
                PrototypeSupportPreferencesStep(
                    onBack: { stepIndex = 1 },
                    onContinue: { supports in
                        onComplete(collectedDietPrefs, collectedCareGoals, supports)
                    }
                )
            }
        }
    }
}

private struct PrototypeCareGoalsStep: View {
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var dexcomViewModel: DexcomConnectionViewModel

    let onBack: () -> Void
    let onContinue: ([String]) -> Void

    @State private var selectedGoals: Set<String> = ["Reduce spikes"]
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
                PrototypePageBackground()
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
                                PrototypeChoicePill(
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

                        PrototypeDexcomConnectionCard(
                            statusTitle: dexcomViewModel.statusTitle,
                            statusDetail: dexcomViewModel.statusLabel,
                            actionTitle: dexcomViewModel.actionTitle,
                            isConnecting: dexcomViewModel.isConnecting,
                            isSyncing: dexcomViewModel.isSyncing,
                            isConnected: dexcomViewModel.connection.status == .connected,
                            errorMessage: dexcomViewModel.connection.status == .error ? dexcomViewModel.errorMessage : nil,
                            onConnect: {
                                Task {
                                    if let authorizationURL = await dexcomViewModel.requestConnectionURL() {
                                        openURL(authorizationURL)
                                    }
                                }
                            },
                            onSync: {
                                Task {
                                    await dexcomViewModel.syncAndLoadSummary()
                                }
                            }
                        )

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Medication reminders")
                                .font(.headline.weight(.semibold))
                            HStack(spacing: 10) {
                                PrototypeChoicePill(
                                    title: "On",
                                    isSelected: wantsMedicationReminders,
                                    action: { wantsMedicationReminders = true }
                                )
                                PrototypeChoicePill(
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

                        Button {
                            onContinue(Array(selectedGoals))
                        } label: {
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
        .task {
            await dexcomViewModel.bootstrapIfNeeded()
        }
    }
}

private struct PrototypeSupportPreferencesStep: View {
    let onBack: () -> Void
    let onContinue: ([String]) -> Void

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
                PrototypePageBackground()
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
                                PrototypeChoicePill(
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

                        Button {
                            onContinue(Array(selectedSupports))
                        } label: {
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

private struct PrototypeHomeView: View {
    @EnvironmentObject private var dexcomViewModel: DexcomConnectionViewModel
    @EnvironmentObject private var mealFlowViewModel: PrototypeMealFlowViewModel

    let onResetToOnboarding: () -> Void

    private enum Destination: Hashable {
        case selectMeals
        case foodLog
        case capture(FoodLoggingMode)
        case plateFeedback
        case cgmData
        case groceries
    }

    @State private var path: [Destination] = []
    @StateObject private var viewModel = PrototypeHomeViewModel()

    var body: some View {
        NavigationStack(path: $path) {
            GeometryReader { geo in
                ZStack {
                    PrototypePageBackground()
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

                            PrototypeSummaryCard(
                                mealsLoggedThisWeek: viewModel.mealsLoggedThisWeek,
                                latestCartItemCount: viewModel.latestCartItemCount,
                                cgmStatusLabel: dexcomViewModel.statusLabel
                            )

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
                                PrototypeDashboardActionCard(
                                    title: "Select meals",
                                    subtitle: "Pick diabetes-friendly options",
                                    icon: "fork.knife",
                                    tint: .green
                                ) {
                                    path.append(.selectMeals)
                                }

                                PrototypeDashboardActionCard(
                                    title: "Log food",
                                    subtitle: "Voice, photo, barcode, or text",
                                    icon: "camera.fill",
                                    tint: .blue
                                ) {
                                    path.append(.foodLog)
                                }

                                PrototypeDashboardActionCard(
                                    title: "See CGM data",
                                    subtitle: "Simple weekly trend and goal",
                                    icon: "waveform.path.ecg",
                                    tint: .teal
                                ) {
                                    path.append(.cgmData)
                                }

                                PrototypeDashboardActionCard(
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
            .task {
                await dexcomViewModel.bootstrapIfNeeded()
                await viewModel.reload()
            }
            .task(id: dexcomViewModel.connection.updatedAt) {
                await viewModel.reload()
            }
            .task(id: mealFlowViewModel.latestMealLog?.id) {
                await viewModel.reload()
            }
            .task(id: mealFlowViewModel.activeCartDraft?.updatedAt) {
                await viewModel.reload()
            }
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .selectMeals:
                    DinnerMealSelectionMockView()
                case .foodLog:
                    FoodLoggingMockView(
                        onModeSelected: { mode in
                            path.append(.capture(mode))
                        }
                    )
                case .capture(let mode):
                    MealCaptureView(mode: mode) { input in
                        Task {
                            if await mealFlowViewModel.logMeal(input: input) {
                                await MainActor.run {
                                    path.append(.plateFeedback)
                                }
                            }
                        }
                    }
                case .plateFeedback:
                    PrototypeMealFeedbackView()
                case .cgmData:
                    PrototypeWeeklyGlucoseView(
                        onPlanMealsForNextWeek: {
                            path.append(.selectMeals)
                        }
                    )
                case .groceries:
                    PrototypeShoppingCartView()
                }
            }
        }
    }
}

private struct PrototypeDexcomConnectionCard: View {
    let statusTitle: String
    let statusDetail: String
    let actionTitle: String
    let isConnecting: Bool
    let isSyncing: Bool
    let isConnected: Bool
    let errorMessage: String?
    let onConnect: () -> Void
    let onSync: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Dexcom connection")
                .font(.headline.weight(.semibold))

            VStack(alignment: .leading, spacing: 4) {
                Text(statusTitle)
                    .font(.subheadline.weight(.semibold))
                Text(statusDetail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let errorMessage, !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 10) {
                Button(action: onConnect) {
                    HStack(spacing: 8) {
                        if isConnecting {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(actionTitle)
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppTheme.primary)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isConnecting)

                if isConnected {
                    Button(action: onSync) {
                        HStack(spacing: 8) {
                            if isSyncing {
                                ProgressView()
                                    .tint(AppTheme.primary)
                            }
                            Text(isSyncing ? "Syncing..." : "Sync now")
                                .font(.subheadline.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(uiColor: .tertiarySystemFill))
                        .foregroundStyle(.primary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isSyncing)
                }
            }
        }
    }
}

private struct PrototypeWeeklyGlucoseView: View {
    @EnvironmentObject private var dexcomViewModel: DexcomConnectionViewModel

    let onPlanMealsForNextWeek: (() -> Void)?

    var body: some View {
        WeeklyGlucoseOverviewMockView(
            summary: dexcomViewModel.weeklySummary,
            cgmStatusLabel: dexcomViewModel.statusLabel,
            errorMessage: dexcomViewModel.errorMessage,
            isSyncing: dexcomViewModel.isSyncing,
            onSync: {
                Task {
                    await dexcomViewModel.syncAndLoadSummary()
                }
            },
            onPlanMealsForNextWeek: onPlanMealsForNextWeek
        )
        .task {
            await dexcomViewModel.bootstrapIfNeeded()
            await dexcomViewModel.loadWeeklySummary()
        }
    }
}

private struct PrototypeSummaryCard: View {
    let mealsLoggedThisWeek: Int
    let latestCartItemCount: Int
    let cgmStatusLabel: String

    var body: some View {
        HStack(spacing: 10) {
            summaryPill(
                title: "Meals",
                value: "\(mealsLoggedThisWeek) this week",
                tint: .blue
            )
            summaryPill(
                title: "Cart",
                value: latestCartItemCount > 0 ? "\(latestCartItemCount) items ready" : "No draft yet",
                tint: .green
            )
            summaryPill(
                title: "CGM",
                value: cgmStatusLabel,
                tint: .teal
            )
        }
    }

    private func summaryPill(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.white.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct PrototypeDashboardActionCard: View {
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

private struct PrototypeChoicePill: View {
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

private struct PrototypePageBackground: View {
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

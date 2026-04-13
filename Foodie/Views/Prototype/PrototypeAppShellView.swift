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
                        // Only register a new user if no ID is stored yet.
                        // Re-running onboarding must not orphan an existing Dexcom connection.
                        if BackendClient.storedUserID == nil {
                            if let response = try? await BackendClient.shared.registerUser(
                                name: "",
                                dietPreferences: dietPrefs,
                                careGoals: careGoals,
                                supportPreferences: supports
                            ) {
                                BackendClient.saveUserID(response.id)
                            }
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
                            isPending: dexcomViewModel.connection.status == .pending,
                            isCheckingStatus: dexcomViewModel.isLoadingStatus,
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
                            },
                            onCheckStatus: {
                                Task {
                                    await dexcomViewModel.refreshConnectionStatus()
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
        case capture(FoodLoggingMode)
        case plateFeedback
    }

    private enum HomeTab: Hashable {
        case food
        case cgm
        case cart
    }

    @State private var path: [Destination] = []
    @State private var selectedTab: HomeTab = .food
    @State private var showMealsSheet = false

    var body: some View {
        NavigationStack(path: $path) {
            TabView(selection: $selectedTab) {
                PrototypeFoodLoggingTab(
                    onResetToOnboarding: onResetToOnboarding,
                    onShowMealsHistory: { showMealsSheet = true },
                    onSelectMeals: {
                        path.append(.selectMeals)
                    },
                    onCapture: { mode in
                        path.append(.capture(mode))
                    }
                )
                .tabItem {
                    Label("Food", systemImage: "camera.fill")
                }
                .tag(HomeTab.food)

                PrototypeWeeklyGlucoseView(
                    hideTabBar: false,
                    onPlanMealsForNextWeek: {
                        path.append(.selectMeals)
                    }
                )
                .tabItem {
                    Label("CGM", systemImage: "waveform.path.ecg")
                }
                .tag(HomeTab.cgm)

                PrototypeShoppingCartView(hideTabBar: false)
                    .tabItem {
                        Label("Cart", systemImage: "cart.fill")
                    }
                    .tag(HomeTab.cart)
            }
            .tint(AppTheme.primary)
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarBackButtonHidden(true)
            .task {
                await dexcomViewModel.bootstrapIfNeeded()
                await mealFlowViewModel.bootstrapIfNeeded()
            }
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .selectMeals:
                    DinnerMealSelectionMockView()
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
                }
            }
            .sheet(isPresented: $showMealsSheet) {
                PrototypeMealHistoryView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(26)
            }
        }
    }
}

private struct PrototypeFoodLoggingTab: View {
    let onResetToOnboarding: () -> Void
    let onShowMealsHistory: () -> Void
    let onSelectMeals: () -> Void
    let onCapture: (FoodLoggingMode) -> Void

    var body: some View {
        GeometryReader { geo in
            ZStack {
                PrototypePageBackground()
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Log food")
                                .font(.system(size: 33, weight: .bold, design: .rounded))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onResetToOnboarding()
                                }
                            Text("Choose one simple way to log a meal")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 12)

                        Button(action: onShowMealsHistory) {
                            HStack(spacing: 6) {
                                Image(systemName: "clock.arrow.circlepath")
                                Text("History")
                            }
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(uiColor: .tertiarySystemFill))
                            .foregroundStyle(.primary)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer(minLength: 28)

                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                        spacing: 12
                    ) {
                        ForEach(PrototypeLoggingOption.allCases, id: \.mode) { option in
                            PrototypeLoggingModeCard(
                                title: option.title,
                                icon: option.systemImage,
                                tint: option.tint
                            ) {
                                onCapture(option.mode)
                            }
                        }
                    }
                    .frame(maxWidth: 370)
                    .frame(maxWidth: .infinity)

                    Spacer(minLength: 18)

                    Button(action: onSelectMeals) {
                        Text("Select meals")
                            .font(.headline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(AppTheme.primary)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 62)
                .padding(.bottom, 24)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
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
    let isPending: Bool
    let isCheckingStatus: Bool
    let errorMessage: String?
    let onConnect: () -> Void
    let onSync: () -> Void
    let onCheckStatus: () -> Void

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

                if isPending {
                    Button(action: onCheckStatus) {
                        HStack(spacing: 8) {
                            if isCheckingStatus {
                                ProgressView()
                                    .tint(AppTheme.primary)
                            }
                            Text(isCheckingStatus ? "Checking..." : "Already done?")
                                .font(.subheadline.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(uiColor: .tertiarySystemFill))
                        .foregroundStyle(.primary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isCheckingStatus)
                }

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

    let hideTabBar: Bool
    let onPlanMealsForNextWeek: (() -> Void)?

    init(hideTabBar: Bool = true, onPlanMealsForNextWeek: (() -> Void)? = nil) {
        self.hideTabBar = hideTabBar
        self.onPlanMealsForNextWeek = onPlanMealsForNextWeek
    }

    var body: some View {
        WeeklyGlucoseOverviewMockView(
            summary: dexcomViewModel.weeklySummary,
            cgmStatusLabel: dexcomViewModel.statusLabel,
            errorMessage: dexcomViewModel.errorMessage,
            isSyncing: dexcomViewModel.isSyncing,
            hideTabBar: hideTabBar,
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
    let onMealsTap: () -> Void
    let onCartTap: () -> Void
    let onCGMTap: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            summaryPill(
                icon: "fork.knife",
                title: "Meals",
                value: "\(mealsLoggedThisWeek) this week",
                tint: .blue,
                action: onMealsTap
            )
            summaryPill(
                icon: "cart.fill",
                title: "Cart",
                value: latestCartItemCount > 0 ? "\(latestCartItemCount) items ready" : "No draft yet",
                tint: .green,
                action: onCartTap
            )
            summaryPill(
                icon: "waveform.path.ecg",
                title: "CGM",
                value: cgmStatusLabel,
                tint: .teal,
                action: onCGMTap
            )
        }
    }

    private func summaryPill(icon: String, title: String, value: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(tint.opacity(0.16))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(tint)
                }

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
            .padding(12)
            .background(.white.opacity(0.96))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(tint.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private enum PrototypeLoggingOption: CaseIterable {
    case takePhoto
    case voiceLog
    case barcodeScan
    case textLog

    var mode: FoodLoggingMode {
        switch self {
        case .takePhoto: return .takePhoto
        case .voiceLog: return .voiceLog
        case .barcodeScan: return .barcodeScan
        case .textLog: return .textLog
        }
    }

    var title: String {
        switch self {
        case .takePhoto: return "Take Photo"
        case .voiceLog: return "Voice Log"
        case .barcodeScan: return "Barcode Scan"
        case .textLog: return "Text Log"
        }
    }

    var systemImage: String {
        switch self {
        case .takePhoto: return "camera.fill"
        case .voiceLog: return "mic.fill"
        case .barcodeScan: return "barcode.viewfinder"
        case .textLog: return "text.bubble.fill"
        }
    }

    var tint: Color {
        switch self {
        case .takePhoto: return Color(red: 0.14, green: 0.53, blue: 0.96)
        case .voiceLog: return Color(red: 0.05, green: 0.66, blue: 0.62)
        case .barcodeScan: return Color(red: 0.95, green: 0.61, blue: 0.16)
        case .textLog: return Color(red: 0.91, green: 0.37, blue: 0.44)
        }
    }
}

private struct PrototypeLoggingModeCard: View {
    let title: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(tint.opacity(0.16))
                        .frame(width: 72, height: 72)
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(tint)
                }

                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 168)
            .background(
                LinearGradient(
                    colors: [.white, tint.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(tint.opacity(0.26), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }
}

private struct PrototypeMealHistoryView: View {
    @State private var meals: [MealLog] = []
    @State private var errorMessage: String?

    private let backendClient = BackendClient.shared
    private let repositories = PrototypeRepositoryContainer.shared

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Meals")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text("Your recent meal history")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                if let errorMessage, meals.isEmpty {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if meals.isEmpty {
                    PrototypeEmptyMealHistoryCard()
                } else {
                    VStack(spacing: 10) {
                        ForEach(meals) { meal in
                            PrototypeMealHistoryRow(meal: meal)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 24)
        .background(Color(uiColor: .systemGroupedBackground))
        .task {
            await loadMeals()
        }
    }

    private func loadMeals() async {
        do {
            let remoteMeals = try await backendClient.fetchRecentMeals(limit: 20)
            for meal in remoteMeals {
                try? await repositories.mealLogs.upsert(meal)
            }
            meals = remoteMeals.sorted(by: { $0.loggedAt > $1.loggedAt })
            errorMessage = nil
        } catch {
            let cachedMeals = ((try? await repositories.mealLogs.fetchAll()) ?? []).sorted(by: { $0.loggedAt > $1.loggedAt })
            meals = cachedMeals
            if cachedMeals.isEmpty {
                errorMessage = error.localizedDescription
            }
        }
    }
}

private struct PrototypeMealHistoryRow: View {
    let meal: MealLog

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tint.opacity(0.14))
                    .frame(width: 42, height: 42)
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(meal.summary)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Text(meal.source.rawValue.capitalized)
                    Text("•")
                    Text(RelativeDateTimeFormatter().localizedString(for: meal.loggedAt, relativeTo: Date()))
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                if let mealType = meal.analysis?.mealType, mealType != .unknown {
                    Text(mealType.rawValue.capitalized)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(tint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(tint.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            Spacer()
        }
        .padding(14)
        .background(.white.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(tint.opacity(0.16), lineWidth: 1)
        )
    }

    private var iconName: String {
        switch meal.source {
        case .photo: return "camera.fill"
        case .voice: return "mic.fill"
        case .text: return "text.bubble.fill"
        case .barcode: return "barcode.viewfinder"
        default: return "fork.knife"
        }
    }

    private var tint: Color {
        switch meal.source {
        case .photo: return Color(red: 0.14, green: 0.53, blue: 0.96)
        case .voice: return Color(red: 0.05, green: 0.66, blue: 0.62)
        case .text: return Color(red: 0.91, green: 0.37, blue: 0.44)
        case .barcode: return Color(red: 0.95, green: 0.61, blue: 0.16)
        default: return .indigo
        }
    }
}

private struct PrototypeEmptyMealHistoryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No meals logged yet")
                .font(.headline.weight(.semibold))
            Text("Log a meal from the home screen to start building your history.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.blue.opacity(0.12), lineWidth: 1)
        )
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

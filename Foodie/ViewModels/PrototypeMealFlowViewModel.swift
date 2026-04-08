//
//  PrototypeMealFlowViewModel.swift
//  Foodie
//

import Foundation

@MainActor
final class PrototypeMealFlowViewModel: ObservableObject {
    static let shared = PrototypeMealFlowViewModel()

    @Published private(set) var latestMealLog: MealLog?
    @Published private(set) var latestInsight: MealInsightContext?
    @Published private(set) var activeCartDraft: CartDraft?
    @Published private(set) var isLoggingMeal = false
    @Published private(set) var isCreatingCart = false
    @Published private(set) var errorMessage: String?

    private let repositories: PrototypeRepositoryContainer
    private let backendClient: BackendClient
    private let engine: MealInsightEngine
    private var didBootstrap = false

    init(repositories: PrototypeRepositoryContainer = .shared,
         backendClient: BackendClient = .shared,
         engine: MealInsightEngine = MealInsightEngine()) {
        self.repositories = repositories
        self.backendClient = backendClient
        self.engine = engine
    }

    func bootstrapIfNeeded() async {
        guard !didBootstrap else { return }
        didBootstrap = true
        await reload()
    }

    func reload() async {
        if let remoteMeals = try? await backendClient.fetchRecentMeals(limit: 3), !remoteMeals.isEmpty {
            for remoteMeal in remoteMeals {
                try? await repositories.mealLogs.upsert(remoteMeal)
            }
        }

        let recentMeals = (try? await repositories.mealLogs.recent(limit: 1)) ?? []
        latestMealLog = recentMeals.first
        activeCartDraft = try? await repositories.carts.fetchLatestDraft()

        let readings = await loadAvailableReadings()
        if let latestMealLog {
            latestInsight = await loadInsight(for: latestMealLog, readings: readings)
        } else {
            latestInsight = nil
        }
    }

    @discardableResult
    func logMeal(using mode: FoodLoggingMode) async -> Bool {
        isLoggingMeal = true
        defer { isLoggingMeal = false }

        let readings = await loadAvailableReadings()
        let draftMealLog = engine.createMealLog(for: mode, using: readings)

        do {
            let persistedMealLog = try await backendClient.createMealLog(draftMealLog)
            try await repositories.mealLogs.upsert(persistedMealLog)
            latestMealLog = persistedMealLog
            latestInsight = await loadInsight(for: persistedMealLog, readings: readings)
            errorMessage = nil
            return true
        } catch {
            do {
                try await repositories.mealLogs.upsert(draftMealLog)
                latestMealLog = draftMealLog
                latestInsight = engine.buildInsight(for: draftMealLog, readings: readings)
                errorMessage = nil
                return true
            } catch {
                errorMessage = error.localizedDescription
                return false
            }
        }
    }

    @discardableResult
    func addSuggestedIngredientsToCart() async -> Bool {
        guard let insight = latestInsight else { return false }

        isCreatingCart = true
        defer { isCreatingCart = false }

        do {
            let existingDraft = try await repositories.carts.fetchLatestDraft()
            let updatedDraft = engine.buildCartDraft(for: insight, existingDraft: existingDraft)
            try await repositories.carts.saveDraft(updatedDraft)
            activeCartDraft = updatedDraft
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func loadAvailableReadings() async -> [GlucoseReading] {
        if let cached = try? await repositories.glucose.fetchReadings(), !cached.isEmpty {
            return cached
        }

        do {
            let remoteReadings = try await backendClient.fetchGlucoseReadings()
            if !remoteReadings.isEmpty {
                try await repositories.glucose.saveReadings(remoteReadings)
            }
            return remoteReadings
        } catch {
            errorMessage = error.localizedDescription
            return []
        }
    }

    private func loadInsight(for mealLog: MealLog, readings: [GlucoseReading]) async -> MealInsightContext {
        do {
            let response = try await backendClient.fetchMealInsight(for: mealLog.id)
            return MealInsightContext(
                mealLog: response.mealLog,
                mealImageName: response.mealImageName,
                suggestionImageName: response.suggestionImageName,
                feedback: response.feedback,
                spikeEvent: response.spikeEvent,
                impact: response.impact,
                suggestedCartItems: response.suggestedCartItems
            )
        } catch {
            return engine.buildInsight(for: mealLog, readings: readings)
        }
    }
}

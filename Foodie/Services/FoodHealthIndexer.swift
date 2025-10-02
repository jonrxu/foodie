//
//  FoodHealthIndexer.swift
//  Foodie
//
//  Created by AI Assistant.
//

import Foundation

final class FoodHealthIndexer {
    static let shared = FoodHealthIndexer()

    private let cache = FoodHealthIndexCache()

    func assess(summary: String) async throws -> FoodHealthAssessment {
        if let cached = cache.value(for: summary) {
            return cached
        }
        do {
            let classified = try await OpenAIClient().classifyFood(summary: summary)
            let axes = FoodHealthAssessment.Axes(nutrientDensity: classified.axes.nutrientDensity,
                                                 processing: classified.axes.processing,
                                                 sugarLoad: classified.axes.sugarLoad,
                                                 saturatedFat: classified.axes.saturatedFat,
                                                 sodium: classified.axes.sodium,
                                                 positives: classified.axes.positives)
            let assessment = FoodHealthAssessment(score: classified.score,
                                                 level: classified.level,
                                                 axes: axes,
                                                 tags: classified.tags,
                                                 highlights: classified.highlights)
            cache.store(assessment, for: summary)
            return assessment
        } catch {
            // Fall back to heuristic analyzer
            let analyzer = FoodHealthAnalyzer(summary: summary)
            let assessment = try analyzer.compute()
            cache.store(assessment, for: summary)
            return assessment
        }
    }
}

private final class FoodHealthIndexCache {
    private var storage: [String: FoodHealthAssessment] = [:]
    private let queue = DispatchQueue(label: "FoodHealthIndexCache")

    func value(for summary: String) -> FoodHealthAssessment? {
        queue.sync { storage[summary] }
    }

    func store(_ assessment: FoodHealthAssessment, for summary: String) {
        queue.async { self.storage[summary] = assessment }
    }
}



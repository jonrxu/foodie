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

        let analyzer = FoodHealthAnalyzer(summary: summary)
        let assessment = try analyzer.compute()
        cache.store(assessment, for: summary)
        return assessment
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



//
//  GlucoseRepository.swift
//  Foodie
//

import Foundation

protocol GlucoseRepository {
    func fetchReadings() async throws -> [GlucoseReading]
    func saveReadings(_ readings: [GlucoseReading]) async throws
    func fetchLatestSummary() async throws -> GlucoseSummary?
    func saveSummary(_ summary: GlucoseSummary) async throws
}

final class LocalGlucoseRepository: GlucoseRepository {
    private let readingsStorage = JSONFileStorage(fileName: "glucose_readings.json")
    private let summaryStorage = JSONFileStorage(fileName: "glucose_summary.json")

    func fetchReadings() async throws -> [GlucoseReading] {
        (readingsStorage.load([GlucoseReading].self) ?? [])
            .sorted(by: { $0.timestamp > $1.timestamp })
    }

    func saveReadings(_ readings: [GlucoseReading]) async throws {
        readingsStorage.save(readings.sorted(by: { $0.timestamp > $1.timestamp }))
    }

    func fetchLatestSummary() async throws -> GlucoseSummary? {
        summaryStorage.load(GlucoseSummary.self)
    }

    func saveSummary(_ summary: GlucoseSummary) async throws {
        summaryStorage.save(summary)
    }
}

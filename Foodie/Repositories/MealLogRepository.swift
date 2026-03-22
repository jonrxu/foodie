//
//  MealLogRepository.swift
//  Foodie
//

import Foundation

protocol MealLogRepository {
    func fetchAll() async throws -> [MealLog]
    func upsert(_ mealLog: MealLog) async throws
    func delete(id: UUID) async throws
}

extension MealLogRepository {
    func recent(limit: Int) async throws -> [MealLog] {
        let logs = try await fetchAll().sorted(by: { $0.loggedAt > $1.loggedAt })
        return Array(logs.prefix(limit))
    }
}

final class LocalMealLogRepository: MealLogRepository {
    private let storage = JSONFileStorage(fileName: "meal_logs_v2.json")
    private let legacyStore: FoodLogStore

    init(legacyStore: FoodLogStore = .shared) {
        self.legacyStore = legacyStore
    }

    func fetchAll() async throws -> [MealLog] {
        let domainLogs = storage.load([MealLog].self) ?? []
        let legacyLogs = legacyStore.load().map(MealLog.init(legacy:))

        var merged: [UUID: MealLog] = [:]
        for log in legacyLogs {
            merged[log.id] = log
        }
        for log in domainLogs {
            merged[log.id] = log
        }

        return merged.values.sorted(by: { $0.loggedAt > $1.loggedAt })
    }

    func upsert(_ mealLog: MealLog) async throws {
        var logs = try await fetchAll()
        if let index = logs.firstIndex(where: { $0.id == mealLog.id }) {
            logs[index] = mealLog
        } else {
            logs.append(mealLog)
        }

        storage.save(logs.sorted(by: { $0.loggedAt > $1.loggedAt }))
        legacyStore.save(logs.map(FoodLogEntry.init(domain:)))
    }

    func delete(id: UUID) async throws {
        let logs = try await fetchAll().filter { $0.id != id }
        storage.save(logs)
        legacyStore.save(logs.map(FoodLogEntry.init(domain:)))
    }
}

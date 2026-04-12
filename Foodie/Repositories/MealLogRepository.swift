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

    func fetchAll() async throws -> [MealLog] {
        return storage.load([MealLog].self) ?? []
    }

    func upsert(_ mealLog: MealLog) async throws {
        var logs = try await fetchAll()
        if let index = logs.firstIndex(where: { $0.id == mealLog.id }) {
            logs[index] = mealLog
        } else {
            logs.append(mealLog)
        }
        storage.save(logs.sorted(by: { $0.loggedAt > $1.loggedAt }))
    }

    func delete(id: UUID) async throws {
        let logs = try await fetchAll().filter { $0.id != id }
        storage.save(logs)
    }
}

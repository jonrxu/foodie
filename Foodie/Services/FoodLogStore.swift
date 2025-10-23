//
//  FoodLogStore.swift
//  Foodie
//
//

import Foundation

final class FoodLogStore {
    static let shared = FoodLogStore()

    private let fileName = "food_logs.json"

    private var url: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent(fileName)
    }

    func load() -> [FoodLogEntry] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601WithFallback
        return (try? decoder.decode([FoodLogEntry].self, from: data)) ?? []
    }

    func save(_ entries: [FoodLogEntry]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601WithFallback
        guard let data = try? encoder.encode(entries) else { return }
        try? data.write(to: url, options: .atomic)
    }
}



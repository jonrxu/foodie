//
//  FoodLogStore.swift
//  Foodie
//
//  Created by AI Assistant.
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
        return (try? JSONDecoder().decode([FoodLogEntry].self, from: data)) ?? []
    }

    func save(_ entries: [FoodLogEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: url, options: .atomic)
    }
}



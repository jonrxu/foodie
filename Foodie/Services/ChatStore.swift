//
//  ChatStore.swift
//  Foodie
//
//  Created by AI Assistant.
//

import Foundation

final class ChatStore {
    static let shared = ChatStore()

    private let fileName = "chat_sessions.json"

    private var url: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent(fileName)
    }

    func loadSessions() -> [ChatSession] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        do {
            return try JSONDecoder().decode([ChatSession].self, from: data)
        } catch {
            return []
        }
    }

    func saveSessions(_ sessions: [ChatSession]) {
        do {
            let data = try JSONEncoder().encode(sessions)
            try data.write(to: url, options: .atomic)
        } catch {
            // Ignore for PoC
        }
    }
}



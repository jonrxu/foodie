//
//  UserProfileStore.swift
//  Foodie
//
//  Created by AI Assistant.
//

import Foundation

final class UserProfileStore {
    static let shared = UserProfileStore()

    private let fileName = "user_profile.json"
    private let queue = DispatchQueue(label: "UserProfileStore.queue", qos: .userInitiated)

    private var url: URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return directory.appendingPathComponent(fileName)
    }

    func load() -> UserProfile? {
        var profile: UserProfile?
        queue.sync {
            guard let data = try? Data(contentsOf: url) else { return }
            profile = try? JSONDecoder().decode(UserProfile.self, from: data)
        }
        return profile
    }

    func save(_ profile: UserProfile) {
        queue.async {
            do {
                let data = try JSONEncoder().encode(profile)
                try data.write(to: self.url, options: .atomic)
            } catch {
                // For now, ignore write failures in production build; add logging if needed.
            }
        }
    }

    func clear() {
        queue.async {
            try? FileManager.default.removeItem(at: self.url)
        }
    }
}



//
//  StreakManager.swift
//  Foodie
//
//

import Foundation

final class StreakManager {
    static let shared = StreakManager()

    private let streakKey = "streakCount"
    private let lastDateKey = "lastInteractionDate"

    func currentStreak() -> Int {
        UserDefaults.standard.integer(forKey: streakKey)
    }

    func touch() -> Int {
        let calendar = Calendar.current
        let today = Date()

        let defaults = UserDefaults.standard
        let lastDate = defaults.object(forKey: lastDateKey) as? Date

        var newStreak = currentStreak()
        if let lastDate = lastDate {
            if calendar.isDateInToday(lastDate) {
                // No change
            } else if let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastDate), to: calendar.startOfDay(for: today)).day, days == 1 {
                newStreak += 1
            } else {
                newStreak = max(1, newStreak == 0 ? 1 : 1)
            }
        } else {
            newStreak = max(1, newStreak == 0 ? 1 : newStreak)
        }

        defaults.set(newStreak, forKey: streakKey)
        defaults.set(today, forKey: lastDateKey)
        return newStreak
    }
}



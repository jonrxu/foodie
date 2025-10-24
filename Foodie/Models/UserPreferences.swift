//
//  UserPreferences.swift
//  Foodie
//
//

import Foundation

final class UserPreferences: ObservableObject {
    static let shared = UserPreferences()

    @Published var dailyCalorieGoal: Int {
        didSet { UserDefaults.standard.set(dailyCalorieGoal, forKey: Keys.calorieGoal) }
    }

    @Published var joinedDate: Date {
        didSet { UserDefaults.standard.set(joinedDate, forKey: Keys.joinedDate) }
    }

    private struct Keys {
        static let calorieGoal = "dailyCalorieGoal"
        static let joinedDate = "joinedDate"
    }

    private init() {
        let storedGoal = UserDefaults.standard.integer(forKey: Keys.calorieGoal)
        dailyCalorieGoal = storedGoal > 0 ? storedGoal : 2000

        if let storedDate = UserDefaults.standard.object(forKey: Keys.joinedDate) as? Date {
            joinedDate = storedDate
        } else {
            let now = Date()
            joinedDate = now
            UserDefaults.standard.set(now, forKey: Keys.joinedDate)
        }
    }
}



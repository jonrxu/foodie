//
//  PrototypeRepositoryContainer.swift
//  Foodie
//

import Foundation

final class PrototypeRepositoryContainer {
    static let shared = PrototypeRepositoryContainer()

    let mealLogs: any MealLogRepository
    let glucose: any GlucoseRepository
    let carts: any CartRepository
    let connections: any ConnectionRepository

    private init(mealLogs: any MealLogRepository = LocalMealLogRepository(),
                 glucose: any GlucoseRepository = LocalGlucoseRepository(),
                 carts: any CartRepository = LocalCartRepository(),
                 connections: any ConnectionRepository = LocalConnectionRepository()) {
        self.mealLogs = mealLogs
        self.glucose = glucose
        self.carts = carts
        self.connections = connections
    }
}

//
//  AgentNotificationRouter.swift
//  Foodie
//

import Foundation
import UIKit
import UserNotifications

struct AgentNotificationRoute: Equatable {
    var targetPath: String
    var recommendationID: UUID?
    var relatedMealLogID: UUID?
}

@MainActor
final class AgentNotificationRouter: ObservableObject {
    static let shared = AgentNotificationRouter()

    @Published var pendingRoute: AgentNotificationRoute?

    func handleUserInfo(_ userInfo: [AnyHashable: Any]) {
        guard let targetPath = userInfo["targetPath"] as? String, !targetPath.isEmpty else { return }
        let recommendationID = (userInfo["recommendationID"] as? String).flatMap(UUID.init(uuidString:))
        let relatedMealLogID = (userInfo["relatedMealLogID"] as? String).flatMap(UUID.init(uuidString:))
        pendingRoute = AgentNotificationRoute(
            targetPath: targetPath,
            recommendationID: recommendationID,
            relatedMealLogID: relatedMealLogID
        )
    }

    func consume() {
        pendingRoute = nil
    }
}

final class AgentNotificationAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        await MainActor.run {
            AgentNotificationRouter.shared.handleUserInfo(response.notification.request.content.userInfo)
        }
    }
}

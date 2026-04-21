//
//  AgentNotificationCenter.swift
//  Foodie
//

import Foundation
import UserNotifications

@MainActor
final class AgentNotificationCenter {
    static let shared = AgentNotificationCenter()

    private let center = UNUserNotificationCenter.current()

    func requestAuthorizationIfNeeded() async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func schedule(notification: AgentNotificationDraft, recommendationID: UUID) async {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = .default
        content.userInfo = [
            "targetPath": notification.targetPath ?? "",
            "recommendationID": recommendationID.uuidString,
            "relatedMealLogID": notification.relatedMealLogID?.uuidString ?? "",
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: notification.id.uuidString,
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }
}

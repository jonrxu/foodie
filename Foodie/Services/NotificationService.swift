//
//  NotificationService.swift
//  Foodie
//
//

import Foundation
import UserNotifications

@MainActor
final class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    /// Request notification permissions and schedule reminders
    func setupNotifications() async {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            
            if granted {
                print("✅ [Notifications] Permission granted")
                scheduleDailyFoodLogReminder()
                scheduleWeeklyGroceryReminder()
            } else {
                print("⚠️ [Notifications] Permission denied")
            }
        } catch {
            print("❌ [Notifications] Error requesting permission: \(error)")
        }
    }
    
    /// Schedule daily reminder to log food (8 PM)
    private func scheduleDailyFoodLogReminder() {
        let center = UNUserNotificationCenter.current()
        
        // Cancel any existing daily reminders
        center.removePendingNotificationRequests(withIdentifiers: ["daily_food_log"])
        
        let content = UNMutableNotificationContent()
        content.title = "Log Your Meals 🥗"
        content.body = "Tap to quickly log what you ate today with voice"
        content.sound = .default
        
        // Trigger at 8 PM daily
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_food_log", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("❌ [Notifications] Failed to schedule daily reminder: \(error)")
            } else {
                print("✅ [Notifications] Daily food log reminder scheduled for 8 PM")
            }
        }
    }
    
    /// Schedule weekly reminder for groceries (Sunday 10 AM)
    private func scheduleWeeklyGroceryReminder() {
        let center = UNUserNotificationCenter.current()
        
        // Cancel any existing weekly reminders
        center.removePendingNotificationRequests(withIdentifiers: ["weekly_grocery"])
        
        let content = UNMutableNotificationContent()
        content.title = "Time to Shop 🛒"
        content.body = "Your smart grocery list is ready. Order with one tap!"
        content.sound = .default
        
        // Trigger on Sunday at 10 AM
        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 10
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly_grocery", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("❌ [Notifications] Failed to schedule weekly reminder: \(error)")
            } else {
                print("✅ [Notifications] Weekly grocery reminder scheduled for Sunday 10 AM")
            }
        }
    }
    
    /// Cancel all scheduled notifications
    func cancelAllNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        print("🚫 [Notifications] All notifications cancelled")
    }
}


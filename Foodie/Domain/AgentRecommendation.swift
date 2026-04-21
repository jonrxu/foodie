//
//  AgentRecommendation.swift
//  Foodie
//

import Foundation

enum AgentRunKind: String, Codable, Hashable {
    case spikeTriggered = "spike_triggered"
    case dailySummary = "daily_summary"
    case weeklyPlanning = "weekly_planning"
}

enum AgentRunStatus: String, Codable, Hashable {
    case completed
    case skipped
    case failed
}

enum AgentNotificationKind: String, Codable, Hashable {
    case logMealPrompt = "log_meal_prompt"
    case mealFeedbackReady = "meal_feedback_ready"
    case dailySummaryReady = "daily_summary_ready"
    case weeklyPlanReady = "weekly_plan_ready"
}

struct AgentNotificationDraft: Identifiable, Codable, Hashable {
    let id: UUID
    var kind: AgentNotificationKind
    var title: String
    var body: String
    var createdAt: Date
    var actionLabel: String?
    var targetPath: String?
    var relatedMealLogID: UUID?
}

struct AgentRecommendation: Identifiable, Codable, Hashable {
    let id: UUID
    var createdAt: Date
    var runKind: AgentRunKind
    var title: String
    var summary: String
    var actionLabel: String?
    var relatedMealLogID: UUID?
    var relatedSpikeStartedAt: Date?
    var readAt: Date?
    var dismissedAt: Date?
    var notificationDraft: AgentNotificationDraft?
}

struct AgentRun: Identifiable, Codable, Hashable {
    let id: UUID
    var kind: AgentRunKind
    var status: AgentRunStatus
    var createdAt: Date
    var completedAt: Date?
    var summary: String
    var sourceEventKey: String?
    var recommendationsCreated: Int
}

struct AgentFeed: Codable, Hashable {
    var runs: [AgentRun]
    var recommendations: [AgentRecommendation]
}

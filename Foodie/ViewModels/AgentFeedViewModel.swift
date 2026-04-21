//
//  AgentFeedViewModel.swift
//  Foodie
//

import Foundation

@MainActor
final class AgentFeedViewModel: ObservableObject {
    static let shared = AgentFeedViewModel()

    @Published private(set) var feed = AgentFeed(runs: [], recommendations: [])
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var unreadRecommendationIDs: Set<UUID> = []

    private let backendClient: BackendClient
    private let notificationCenter: AgentNotificationCenter
    private var didBootstrap = false

    private static let unreadIDsKey = "agent_feed_unread_ids"
    private static let deliveredNotificationIDsKey = "agent_feed_delivered_notification_ids"

    init(
        backendClient: BackendClient = .shared,
        notificationCenter: AgentNotificationCenter = .shared
    ) {
        self.backendClient = backendClient
        self.notificationCenter = notificationCenter
    }

    var latestRecommendation: AgentRecommendation? {
        visibleRecommendations.sorted(by: { $0.createdAt > $1.createdAt }).first
    }

    var visibleRecommendations: [AgentRecommendation] {
        feed.recommendations.filter { $0.dismissedAt == nil }
    }

    var unreadCount: Int {
        unreadRecommendationIDs.intersection(Set(visibleRecommendations.map(\.id))).count
    }

    func bootstrapIfNeeded() async {
        guard !didBootstrap else { return }
        didBootstrap = true
        unreadRecommendationIDs = Self.loadIDSet(forKey: Self.unreadIDsKey)
        await notificationCenter.requestAuthorizationIfNeeded()
        await refresh()
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        do {
            feed = try await backendClient.fetchAgentFeed(limit: 20)
            let visibleIDs = Set(visibleRecommendations.map(\.id))
            unreadRecommendationIDs = unreadRecommendationIDs.intersection(visibleIDs)
            for recommendation in visibleRecommendations {
                if recommendation.readAt == nil, !unreadRecommendationIDs.contains(recommendation.id) {
                    unreadRecommendationIDs.insert(recommendation.id)
                }
                if let notification = recommendation.notificationDraft {
                    await maybeSchedule(notification: notification, recommendationID: recommendation.id)
                }
            }
            Self.saveIDSet(unreadRecommendationIDs, forKey: Self.unreadIDsKey)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markRead(_ recommendation: AgentRecommendation) {
        markRead(recommendationID: recommendation.id)
    }

    func markRead(recommendationID: UUID) {
        unreadRecommendationIDs.remove(recommendationID)
        Self.saveIDSet(unreadRecommendationIDs, forKey: Self.unreadIDsKey)
        Task {
            _ = try? await backendClient.markAgentRecommendationRead(recommendationID)
            await refresh()
        }
    }

    func dismiss(_ recommendation: AgentRecommendation) {
        unreadRecommendationIDs.remove(recommendation.id)
        Self.saveIDSet(unreadRecommendationIDs, forKey: Self.unreadIDsKey)
        Task {
            _ = try? await backendClient.dismissAgentRecommendation(recommendation.id)
            await refresh()
        }
    }

    func isUnread(_ recommendation: AgentRecommendation) -> Bool {
        unreadRecommendationIDs.contains(recommendation.id)
    }

    private func maybeSchedule(notification: AgentNotificationDraft, recommendationID: UUID) async {
        var delivered = Self.loadIDSet(forKey: Self.deliveredNotificationIDsKey)
        guard !delivered.contains(notification.id) else { return }
        await notificationCenter.schedule(notification: notification, recommendationID: recommendationID)
        delivered.insert(notification.id)
        Self.saveIDSet(delivered, forKey: Self.deliveredNotificationIDsKey)
    }

    private static func loadIDSet(forKey key: String) -> Set<UUID> {
        let strings = UserDefaults.standard.stringArray(forKey: key) ?? []
        return Set(strings.compactMap(UUID.init(uuidString:)))
    }

    private static func saveIDSet(_ ids: Set<UUID>, forKey key: String) {
        UserDefaults.standard.set(ids.map(\.uuidString), forKey: key)
    }
}

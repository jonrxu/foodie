//
//  CoachViewModel.swift
//  Foodie
//
//  Created by AI Assistant.
//

import Foundation
import Combine
import UIKit
import SwiftUI

final class CoachViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = [
        ChatMessage(role: .assistant, content: "Hey! I’m Foodie 🥗 Your friendly coach for building healthy eating habits. What’s your goal today?")
    ]
    @Published var inputText: String = ""
    @Published var isStreaming: Bool = false
    @Published var streakCount: Int = StreakManager.shared.currentStreak()
    @Published var lastError: String?
    @Published var showConfetti: Bool = false
    @Published var sessions: [ChatSession] = []
    @Published var currentSessionId: UUID?

    let quickPrompts: [String] = [
        "Plan my week",
        "15‑min dinners",
        "Healthy takeout",
        "Grocery list under $50"
    ]

    private let client = OpenAIClient()
    private var streamTask: Task<Void, Never>?

    private let baseSystemPrompt: String = {
        """
        You are Foodie, a friendly nutrition coach. Goals: improve healthy eating with realistic, budget-aware, time-aware advice. Always:
        - Ask 1 clarifying question only if needed.
        - Return clear, step-by-step actions with quantities and approximations.
        - Offer 2-3 swaps for dietary preferences (veg, gluten-free, dairy-free).
        - Keep plans simple: ingredients <= 8 per meal. Include grocery list and prep tips.
        - Be concise; avoid medical claims.
        - Use simple Markdown for readability: *italics* and **bold** for emphasis, short bullet lists when helpful. No tables.
        """
    }()

    func onAppear() {
        streakCount = StreakManager.shared.currentStreak()
        sessions = ChatStore.shared.loadSessions().sorted(by: { $0.updatedAt > $1.updatedAt })
        if let first = sessions.first {
            currentSessionId = first.id
            messages = first.messages
        } else {
            startNewSession()
        }
    }

    func applyQuickPrompt(_ text: String) {
        inputText = text
    }

    func sendCurrentInput() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, isStreaming == false else { return }
        inputText = ""
        send(text: trimmed)
    }

    func send(text: String) {
        var history = messages
        let userMessage = ChatMessage(role: .user, content: text)
        history.append(userMessage)
        messages.append(userMessage)

        let assistantPlaceholder = ChatMessage(role: .assistant, content: "")
        messages.append(assistantPlaceholder)

        isStreaming = true
        lastError = nil

        streamTask?.cancel()
        streamTask = Task { [weak self] in
            guard let self = self else { return }
            do {
                let prompt = self.dynamicSystemPrompt()
                try await client.streamChat(systemPrompt: prompt, messages: history) { token in
                    DispatchQueue.main.async {
                        guard let idx = self.messages.lastIndex(where: { $0.role == .assistant }) else { return }
                        self.messages[idx].content.append(token)
                    }
                }
                await MainActor.run {
                    self.isStreaming = false
                    let previous = self.streakCount
                    let updated = StreakManager.shared.touch()
                    self.streakCount = updated
                    if updated > previous {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        self.showConfetti = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                            self.showConfetti = false
                        }
                    }
                    self.streamTask = nil
                    self.persistCurrentSession()
                }
            } catch {
                if error is CancellationError {
                    await MainActor.run {
                        self.isStreaming = false
                        self.streamTask = nil
                    }
                } else {
                    await MainActor.run {
                        self.isStreaming = false
                        self.lastError = error.localizedDescription
                        self.streamTask = nil
                    }
                }
            }
        }
    }

    func cancelStreaming() {
        streamTask?.cancel()
        streamTask = nil
        isStreaming = false
    }

    func startNewSession() {
        let welcome = ChatMessage(role: .assistant, content: "Hey! I’m Foodie 🍽️ Your friendly coach for building healthy eating habits. What’s your goal today?")
        messages = [welcome]
        let session = ChatSession(title: "New chat", messages: messages)
        sessions.insert(session, at: 0)
        currentSessionId = session.id
        ChatStore.shared.saveSessions(sessions)
    }

    func clearCurrentChat() {
        guard let id = currentSessionId, let idx = sessions.firstIndex(where: { $0.id == id }) else {
            startNewSession(); return
        }
        let welcome = ChatMessage(role: .assistant, content: "Hey! I’m Foodie 🍽️ Your friendly coach for building healthy eating habits. What’s your goal today?")
        messages = [welcome]
        sessions[idx].messages = messages
        sessions[idx].updatedAt = Date()
        ChatStore.shared.saveSessions(sessions)
    }

    func loadSession(_ session: ChatSession) {
        currentSessionId = session.id
        messages = session.messages
    }

    func deleteSession(_ session: ChatSession) {
        guard let idx = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        withAnimation(.easeInOut) {
            sessions.remove(at: idx)
        }
        ChatStore.shared.saveSessions(sessions)
        if currentSessionId == session.id {
            startNewSession()
        }
    }

    private func persistCurrentSession() {
        let title = messages.first(where: { $0.role == .user })?.content.split(separator: "\n").first.map(String.init) ?? "Chat"
        if let id = currentSessionId, let idx = sessions.firstIndex(where: { $0.id == id }) {
            sessions[idx].messages = messages
            sessions[idx].title = title
            sessions[idx].updatedAt = Date()
        } else {
            let new = ChatSession(title: title, messages: messages)
            sessions.insert(new, at: 0)
            currentSessionId = new.id
        }
        ChatStore.shared.saveSessions(sessions)
    }
}

extension CoachViewModel {
    private func dynamicSystemPrompt() -> String {
        // Include recent meal history so the model can tailor recommendations without revealing the context in the chat transcript.
        var prompt = baseSystemPrompt
        let preferences = UserPreferencesStore.shared.loadDietaryPreferences()
        if preferences.isEmpty == false {
            prompt += "\n\nUser dietary preferences (keep in mind when planning):\n" + preferences
        }

        let context = foodLogContext()
        if !context.isEmpty {
            prompt += "\n\nUser meal log context for personalized advice:\n" + context
        }
        return prompt
    }

    private func foodLogContext() -> String {
        let logs = FoodLogStore.shared.load()
        guard logs.isEmpty == false else { return "" }

        let calendar = Calendar.current
        let groups = Dictionary(grouping: logs) { calendar.startOfDay(for: $0.date) }
        let sortedDays = groups.keys.sorted(by: { $0 > $1 }).prefix(3)

        var sections: [String] = []
        for day in sortedDays {
            guard let entries = groups[day]?.sorted(by: { $0.date < $1.date }) else { continue }
            let header: String
            if calendar.isDateInToday(day) {
                header = "Today (" + Self.dayFormatter.string(from: day) + ")"
            } else if calendar.isDateInYesterday(day) {
                header = "Yesterday (" + Self.dayFormatter.string(from: day) + ")"
            } else {
                header = Self.dayFormatter.string(from: day)
            }

            let lines = entries.map { entry -> String in
                let time = Self.timeFormatter.string(from: entry.date)
                return "- \(time): \(entry.summary)"
            }
            sections.append(([header] + lines).joined(separator: "\n"))
        }

        return sections.joined(separator: "\n\n")
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}


//
//  CoachViewModel.swift
//  Foodie
//
//  Created by AI Assistant.
//

import Foundation
import Combine

final class CoachViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = [
        ChatMessage(role: .assistant, content: "Hey! I’m Foodie 🥗 Your friendly coach for building healthy eating habits. What’s your goal today?")
    ]
    @Published var inputText: String = ""
    @Published var isStreaming: Bool = false
    @Published var streakCount: Int = StreakManager.shared.currentStreak()
    @Published var lastError: String?

    let quickPrompts: [String] = [
        "Plan my week",
        "15‑min dinners",
        "Healthy takeout",
        "Grocery list under $50"
    ]

    private let client = OpenAIClient()

    private let systemPrompt: String = {
        """
        You are Foodie, a friendly nutrition coach. Goals: improve healthy eating with realistic, budget-aware, time-aware advice. Always:
        - Ask 1 clarifying question only if needed.
        - Return clear, step-by-step actions with quantities and approximations.
        - Offer 2-3 swaps for dietary preferences (veg, gluten-free, dairy-free).
        - Keep plans simple: ingredients <= 8 per meal. Include grocery list and prep tips.
        - Be concise; avoid medical claims.
        """
    }()

    func onAppear() {
        streakCount = StreakManager.shared.currentStreak()
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

        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await client.streamChat(systemPrompt: systemPrompt, messages: history) { token in
                    DispatchQueue.main.async {
                        guard let idx = self.messages.lastIndex(where: { $0.role == .assistant }) else { return }
                        self.messages[idx].content.append(token)
                    }
                }
                await MainActor.run {
                    self.isStreaming = false
                    self.streakCount = StreakManager.shared.touch()
                }
            } catch {
                await MainActor.run {
                    self.isStreaming = false
                    self.lastError = error.localizedDescription
                }
            }
        }
    }
}



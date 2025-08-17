//
//  MessageBubble.swift
//  Foodie
//
//  Created by AI Assistant.
//

import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage

    var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 24) }
            Text(message.content)
                .padding(12)
                .background(bubbleBackground)
                .foregroundStyle(isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isUser ? Color.clear : Color.black.opacity(0.05), lineWidth: 1)
                )
            if !isUser { Spacer(minLength: 24) }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
        .padding(.vertical, 4)
        .padding(.horizontal)
    }

    private var bubbleBackground: some View {
        Group {
            if isUser {
                LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
            } else {
                Rectangle().fill(.ultraThinMaterial)
            }
        }
    }
}

#Preview {
    VStack {
        MessageBubble(message: ChatMessage(role: .assistant, content: "Hello! How can I help?"))
        MessageBubble(message: ChatMessage(role: .user, content: "Plan my week"))
    }
    .background(Color(.systemGroupedBackground))
}



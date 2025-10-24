//
//  MessageBubble.swift
//  Foodie
//
//

import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage

    var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 24) }
            messageText
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

    @ViewBuilder
    private var messageText: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(parseLines(message.content), id: \.self.id) { line in
                switch line.kind {
                case .header:
                    buildInlineText(line.text)
                        .font(.headline)
                        .bold()
                case .bullet:
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("•")
                            .bold()
                        buildInlineText(line.text)
                    }
                case .paragraph:
                    buildInlineText(line.text)
                }
            }
        }
    }

    private enum LineKind { case header, bullet, paragraph }
    private struct ParsedLine: Hashable { let id = UUID(); let kind: LineKind; let text: String }

    private func parseLines(_ content: String) -> [ParsedLine] {
        let rawLines = content.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        return rawLines.map { raw in
            let trimmedLeading = raw.drop { $0 == " " || $0 == "\t" }
            // Headers: lines beginning with 3 or more '#', with or without a following space
            if let first = trimmedLeading.first, first == "#" {
                var count = 0
                var idx = trimmedLeading.startIndex
                while idx < trimmedLeading.endIndex, trimmedLeading[idx] == "#" {
                    count += 1
                    idx = trimmedLeading.index(after: idx)
                }
                if count >= 3 {
                    // Drop optional single space after hashes
                    if idx < trimmedLeading.endIndex, trimmedLeading[idx] == " " { idx = trimmedLeading.index(after: idx) }
                    let text = String(trimmedLeading[idx...])
                    return ParsedLine(kind: .header, text: text)
                }
            }
            // Bullets: '-', '•', '–', '—' after optional indentation
            if trimmedLeading.hasPrefix("- ") {
                return ParsedLine(kind: .bullet, text: String(trimmedLeading.dropFirst(2)))
            }
            if trimmedLeading.hasPrefix("• ") {
                return ParsedLine(kind: .bullet, text: String(trimmedLeading.dropFirst(2)))
            }
            if trimmedLeading.hasPrefix("– ") { // en dash
                return ParsedLine(kind: .bullet, text: String(trimmedLeading.dropFirst(2)))
            }
            if trimmedLeading.hasPrefix("— ") { // em dash
                return ParsedLine(kind: .bullet, text: String(trimmedLeading.dropFirst(2)))
            }
            return ParsedLine(kind: .paragraph, text: String(trimmedLeading))
        }
    }

    // Builds a Text view with manual inline formatting: **bold**, *italics*
    private func buildInlineText(_ s: String) -> Text {
        var result = Text("")
        var i = s.startIndex
        func append(_ t: Text) { result = result + t }

        while i < s.endIndex {
            if s[i] == "*" {
                let next = s.index(after: i)
                if next < s.endIndex, s[next] == "*" {
                    // Bold
                    let start = s.index(i, offsetBy: 2)
                    if let end = s.range(of: "**", range: start..<s.endIndex)?.lowerBound {
                        let inner = String(s[start..<end])
                        append(Text(inner).bold())
                        i = s.index(end, offsetBy: 2)
                        continue
                    }
                } else {
                    // Italic
                    let start = next
                    if let end = s[start...].firstIndex(of: "*") {
                        let inner = String(s[start..<end])
                        append(Text(inner).italic())
                        i = s.index(after: end)
                        continue
                    }
                }
            }
            // Fallback: append one character
            append(Text(String(s[i])))
            i = s.index(after: i)
        }
        return result
    }

    private var bubbleBackground: some View {
        Group {
            if isUser {
                Rectangle().fill(Color.blue)
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



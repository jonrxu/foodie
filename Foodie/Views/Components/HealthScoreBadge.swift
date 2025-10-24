//
//  HealthScoreBadge.swift
//  Foodie
//
//

import SwiftUI

struct HealthScoreBadge: View {
    let score: Int?
    let level: String?

    init(score: Int?, level: String? = nil) {
        self.score = score
        self.level = level
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(displayScore)
                .font(.system(size: 18, weight: .bold))
            Text(levelDisplay)
                .font(.caption2)
                .bold()
        }
        .foregroundStyle(.white)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(gradient)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var displayScore: String {
        if let score { return "\(score)" }
        return "--"
    }

    private var levelDisplay: String {
        level ?? "HI"
    }

    private var gradient: LinearGradient {
        let colors: [Color]
        let value = score ?? -1
        switch value {
        case 80...100:
            colors = [Color.green.opacity(0.85), Color.teal]
        case 60..<80:
            colors = [Color.yellow.opacity(0.85), Color.orange]
        case 0..<60:
            colors = [Color.red.opacity(0.85), Color.pink]
        default:
            colors = [Color.gray.opacity(0.6), Color.gray.opacity(0.8)]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

#Preview {
    HStack(spacing: 16) {
        HealthScoreBadge(score: 92, level: "A")
        HealthScoreBadge(score: 74, level: "B")
        HealthScoreBadge(score: 48, level: "D")
        HealthScoreBadge(score: nil, level: nil)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}



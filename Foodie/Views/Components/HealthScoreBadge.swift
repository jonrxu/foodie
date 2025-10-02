//
//  HealthScoreBadge.swift
//  Foodie
//
//  Created by AI Assistant.
//

import SwiftUI

struct HealthScoreBadge: View {
    let score: Int?

    var body: some View {
        VStack(spacing: 6) {
            Text(displayScore)
                .font(.system(size: 18, weight: .bold))
            Text("HI")
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

    private var gradient: LinearGradient {
        let colors: [Color]
        switch score ?? -1 {
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
        HealthScoreBadge(score: 92)
        HealthScoreBadge(score: 74)
        HealthScoreBadge(score: 48)
        HealthScoreBadge(score: nil)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}



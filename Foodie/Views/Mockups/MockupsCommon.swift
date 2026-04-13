//
//  MockupsCommon.swift
//  Foodie
//
//  Shared UI helpers for demo-only mock screens.
//

import SwiftUI

struct AdviceLine: View {
    let systemImage: String
    let color: Color
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 18)
                .padding(.top, 2)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct BalancedPlateDiagram: View {
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = size / 2

            ZStack {
                // Base circle
                Circle()
                    .fill(Color(uiColor: .systemBackground))
                    .overlay(
                        Circle()
                            .stroke(Color(uiColor: .separator).opacity(0.3), lineWidth: 1)
                    )

                // Left half: non-starchy vegetables
                Path { path in
                    path.addArc(center: CGPoint(x: radius, y: radius),
                                radius: radius,
                                startAngle: .degrees(90),
                                endAngle: .degrees(270),
                                clockwise: false)
                    path.addLine(to: CGPoint(x: radius, y: radius))
                }
                .fill(Color.green.opacity(0.6))

                // Top-right quarter: carbs
                Path { path in
                    path.move(to: CGPoint(x: radius, y: radius))
                    path.addArc(center: CGPoint(x: radius, y: radius),
                                radius: radius,
                                startAngle: .degrees(270),
                                endAngle: .degrees(0),
                                clockwise: false)
                    path.closeSubpath()
                }
                .fill(Color.orange.opacity(0.7))

                // Bottom-right quarter: protein
                Path { path in
                    path.move(to: CGPoint(x: radius, y: radius))
                    path.addArc(center: CGPoint(x: radius, y: radius),
                                radius: radius,
                                startAngle: .degrees(0),
                                endAngle: .degrees(90),
                                clockwise: false)
                    path.closeSubpath()
                }
                .fill(Color.red.opacity(0.7))

                VStack(spacing: 10) {
                    Text("Non-starchy\nvegetables")
                        .font(.caption).bold()
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)

                    HStack(spacing: 10) {
                        Text("Carb foods")
                            .font(.caption).bold()
                            .foregroundStyle(.white)
                        Text("Protein foods")
                            .font(.caption).bold()
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(10)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

extension View {
    /// Hides the app TabView tab bar for full-screen demo mockups (iOS 16+).
    @ViewBuilder
    func mockupsFullscreen() -> some View {
        if #available(iOS 16.0, *) {
            self
                .toolbar(.hidden, for: .tabBar)
                .toolbarBackground(.hidden, for: .tabBar)
        } else {
            self
        }
    }
}

struct PrototypeTabBarVisibilityModifier: ViewModifier {
    let hideTabBar: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if hideTabBar {
            content.mockupsFullscreen()
        } else {
            content
        }
    }
}

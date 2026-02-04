//
//  PlateFeedbackMockView.swift
//  Foodie
//
//  Mock: plate feedback with diabetes plate model.
//

import SwiftUI

struct PlateFeedbackMockView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                plateModelCard
                nutritionCard
                coachCard
            }
            .padding()
        }
        .background(AppTheme.background)
        .navigationTitle("Plate Feedback")
        .navigationBarTitleDisplayMode(.inline)
        .mockupsFullscreen()
        .navigationBarBackButtonHidden(true)
    }

    private var plateModelCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(uiColor: .tertiarySystemFill))
                        .frame(width: 46, height: 46)
                    Image(systemName: "fork.knife")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Chicken burrito bowl")
                        .font(.subheadline).bold()
                    Text("Lunch")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack {
                Text("Plate model")
                    .font(.headline)
                Spacer()
                Text("660 cal (est.)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                BalancedPlateRings(vegProgress: 0.7, carbProgress: 0.45, proteinProgress: 0.55)
                    .frame(width: 140, height: 140)

                VStack(alignment: .leading, spacing: 8) {
                    PlateLegendRow(color: .green, title: "Non‑starchy vegetables", detail: "Half plate")
                    PlateLegendRow(color: .orange, title: "Carb foods", detail: "Quarter plate")
                    PlateLegendRow(color: .red, title: "Protein foods", detail: "Quarter plate")
                }
            }
            .padding(12)
            .background(Color(uiColor: .systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(uiColor: .separator).opacity(0.2), lineWidth: 1)
            )
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var nutritionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key nutrition details")
                .font(.headline)

            VStack(spacing: 10) {
                MetricRow(title: "Fiber", value: "11g", hint: nil, systemImage: "leaf.fill", color: .green)
                MetricRow(title: "Added sugar", value: "6g", hint: nil, systemImage: "cube.fill", color: .pink)
                MetricRow(title: "Sodium", value: "980mg", hint: nil, systemImage: "drop.triangle.fill", color: .orange)
                MetricRow(title: "Sat. fat", value: "7g", hint: nil, systemImage: "flame.fill", color: .red)
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var coachCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Coach feedback")
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                Text("What went well")
                    .font(.subheadline).bold()
                AdviceLine(systemImage: "checkmark.circle.fill", color: .green, text: "Nice mix of fiber + protein (beans + chicken).")
                AdviceLine(systemImage: "checkmark.circle.fill", color: .green, text: "Solid meal volume if you add veggies.")

                Divider().opacity(0.3)

                Text("Opportunities")
                    .font(.subheadline).bold()
                AdviceLine(systemImage: "wand.and.stars", color: AppTheme.primary, text: "Try a smaller rice portion.")
                AdviceLine(systemImage: "wand.and.stars", color: AppTheme.primary, text: "Watch sauces and cheese for sodium.")
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct BalancedPlateRings: View {
    let vegProgress: CGFloat
    let carbProgress: CGFloat
    let proteinProgress: CGFloat

    var body: some View {
        ZStack {
            Ring(progress: vegProgress, color: .green, lineWidth: 12, inset: 2)
            Ring(progress: proteinProgress, color: .red, lineWidth: 12, inset: 18)
            Ring(progress: carbProgress, color: .orange, lineWidth: 12, inset: 34)

            EmptyView()
        }
    }
}

private struct Ring: View {
    let progress: CGFloat
    let color: Color
    let lineWidth: CGFloat
    let inset: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)
                .padding(inset)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [color.opacity(0.7), color]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .padding(inset)
        }
    }
}

private struct PlateLegendRow: View {
    let color: Color
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline).bold()
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct MetricRow: View {
    let title: String
    let value: String
    let hint: String?
    let systemImage: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 18)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.subheadline).bold()
                    Spacer()
                    Text(value)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let hint {
                    Text(hint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        PlateFeedbackMockView()
    }
}

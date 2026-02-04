//
//  WeeklyGlucoseOverviewMockView.swift
//  Foodie
//
//  CGM demo (Slide 2): weekly overview of glucose + key stats.
//

import SwiftUI
import Foundation

struct WeeklyGlucoseOverviewMockView: View {
    private let sample = CGMWeeklySample(
        timeInRangePercent: 78,
        avgGlucose: 118,
        gmi: 6.1,
        variabilityPercent: 29,
        lowsCount: 2,
        highsCount: 5,
        estimatedA1cText: "Est. A1C 6.1%",
        weekLabel: "Last 7 days",
        dayLabels: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
        dailyTIR: [74, 80, 69, 83, 77, 81, 78],
        dailyAvg: [122, 116, 128, 112, 119, 115, 118]
    )

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard
                timeInRangeCard
                insightsCard
            }
            .padding()
        }
        .background(AppTheme.background)
        .navigationTitle("Weekly Glucose")
        .navigationBarTitleDisplayMode(.inline)
        .mockupsFullscreen()
        .navigationBarBackButtonHidden(true)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppTheme.primary.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("CGM overview")
                        .font(.headline)
                    Text("Last week")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("Weekly snapshot")
                    .font(.caption).bold()
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color(uiColor: .tertiarySystemFill))
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var timeInRangeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly summary")
                .font(.headline)

            Text("You stayed in a healthy range most of the week.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                MetricPill(systemImage: "checkmark.circle.fill", text: "Mostly steady", color: .green)
                MetricPill(systemImage: "moon.stars.fill", text: "Nights calm", color: .blue)
                MetricPill(systemImage: "fork.knife", text: "Meals balanced", color: .orange)
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Coach insights (mock)")
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                AdviceLine(systemImage: "sparkles", color: AppTheme.primary, text: "Nice consistency this week. Keep the simple habits.")
                AdviceLine(systemImage: "fork.knife", color: .orange, text: "If dinner runs higher, add a little more fiber or protein.")
                AdviceLine(systemImage: "figure.walk", color: .green, text: "A 10–15 minute walk after meals could reduce post‑meal spikes.")
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct CGMWeeklySample {
    let timeInRangePercent: Int
    let avgGlucose: Int
    let gmi: Double
    let variabilityPercent: Int
    let lowsCount: Int
    let highsCount: Int
    let estimatedA1cText: String
    let weekLabel: String
    let dayLabels: [String]
    let dailyTIR: [Int]
    let dailyAvg: [Int]
}

private struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.subheadline).bold()
                    .foregroundStyle(.primary)
                Spacer()
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value)
                    .font(.title2).bold()
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct DaySelector: View {
    let labels: [String]
    @Binding var selectedIndex: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(labels.enumerated()), id: \.offset) { idx, label in
                    Button {
                        selectedIndex = idx
                    } label: {
                        Text(label)
                            .font(.subheadline).bold()
                            .foregroundStyle(idx == selectedIndex ? .white : .secondary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(idx == selectedIndex ? AppTheme.primary : Color(uiColor: .tertiarySystemFill))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct BarChart: View {
    let values: [Double]
    let labels: [String]
    let selectedIndex: Int
    let barColor: Color

    var body: some View {
        GeometryReader { geo in
            let maxV = max(values.max() ?? 1, 1)
            let barWidth = max(10, (geo.size.width - CGFloat(values.count - 1) * 10) / CGFloat(values.count))
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(Array(values.enumerated()), id: \.offset) { idx, v in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(idx == selectedIndex ? barColor : barColor.opacity(0.35))
                            .frame(width: barWidth, height: max(8, geo.size.height * (v / maxV)))

                        Text(labels.indices.contains(idx) ? labels[idx] : "")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
        .padding(12)
        .background(Color(uiColor: .tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct MetricPill: View {
    let systemImage: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
            Text(text)
                .font(.caption).bold()
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Color(uiColor: .tertiarySystemFill))
        .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        WeeklyGlucoseOverviewMockView()
    }
}

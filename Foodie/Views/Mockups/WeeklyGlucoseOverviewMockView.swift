//
//  WeeklyGlucoseOverviewMockView.swift
//  Foodie
//
//  CGM demo (Slide 2): weekly overview of glucose + key stats.
//

import SwiftUI
import Foundation

struct WeeklyGlucoseOverviewMockView: View {
    @Environment(\.dismiss) private var dismiss
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
                weeklyPatternCard
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Text("Get Recommendations")
                        .font(.headline)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                        .background(AppTheme.primary)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(uiColor: .systemBackground))
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

            HStack {
                Text("Time in range")
                    .font(.subheadline).bold()
                Spacer()
                Text("\(sample.timeInRangePercent)%")
                    .font(.subheadline).bold()
                    .foregroundStyle(AppTheme.primary)
            }

            Text("Goal: 70–180 mg/dL")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ProgressView(value: Double(sample.timeInRangePercent), total: 100)
                .tint(AppTheme.primary)

            Text("You stayed in range most days.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                MetricPill(systemImage: "arrow.down.right", text: "2 lows", color: .red)
                MetricPill(systemImage: "arrow.up.right", text: "5 highs", color: .orange)
                MetricPill(systemImage: "chart.line.uptrend.xyaxis", text: "Variability", color: .blue)
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var weeklyPatternCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Weekly pattern")
                    .font(.headline)
                Spacer()
                Text("Avg 118")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            BarChart(
                values: sample.dailyTIR.map { Double($0) },
                labels: sample.dayLabels,
                barColor: AppTheme.primary
            )
            .frame(height: 140)

            Text("Bars show % time in range by day.")
                .font(.caption)
                .foregroundStyle(.secondary)
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

private struct BarChart: View {
    let values: [Double]
    let labels: [String]
    let barColor: Color

    var body: some View {
        GeometryReader { geo in
            let maxV = max(values.max() ?? 1, 1)
            let barWidth = max(10, (geo.size.width - CGFloat(values.count - 1) * 10) / CGFloat(values.count))
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(Array(values.enumerated()), id: \.offset) { idx, v in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(barColor.opacity(0.45))
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
        .padding(.bottom, 14)
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

//
//  NighttimeGlucoseMockView.swift
//  Foodie
//
//  CGM demo (Step 2): nighttime summary (last 7 days).
//

import SwiftUI
import Foundation

struct NighttimeGlucoseMockView: View {
    private enum MetricMode: String, CaseIterable, Identifiable {
        case nightsAboveRange = "Nights Above Range"
        case avgNightGlucose = "Avg Night Glucose"
        var id: String { rawValue }
    }

    @State private var mode: MetricMode = .nightsAboveRange

    private let sample = NighttimeCGMSample(
        windowLabel: "Night window: 12:00 AM – 6:00 AM",
        rangeLabel: "Target: 70–180 mg/dL",
        nightsAboveRange: 3,
        totalNights: 7,
        avgNightGlucose: 132,
        avgMinutesAboveRange: 38,
        avgMinutesBelowRange: 6,
        nightlyAvg: [128, 141, 152, 126, 135, 121, 132],
        nightlyMinutesAboveRange: [22, 48, 71, 18, 34, 12, 38],
        dayLabels: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    )

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard
                primaryMetricCard
                breakdownCard
                trendCard
                coachCard
            }
            .padding()
        }
        .background(AppTheme.background)
        .navigationTitle("Nighttime")
        .navigationBarTitleDisplayMode(.inline)
        .mockupsFullscreen()
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppTheme.primary.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Nighttime glucose")
                        .font(.headline)
                    Text("Last 7 days")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Divider().opacity(0.25)

            VStack(alignment: .leading, spacing: 6) {
                Text(sample.windowLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(sample.rangeLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var primaryMetricCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Metric", selection: $mode) {
                ForEach(MetricMode.allCases) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)

            if mode == .nightsAboveRange {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(sample.nightsAboveRange)")
                        .font(.system(size: 42, weight: .bold))
                    Text("/ \(sample.totalNights) nights")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                Text("You were above range at night on \(sample.nightsAboveRange) of the last \(sample.totalNights) nights.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(sample.avgNightGlucose)")
                        .font(.system(size: 42, weight: .bold))
                    Text("mg/dL")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Spacer()
                }

                Text("Your average glucose during the night window was \(sample.avgNightGlucose) mg/dL.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var breakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Night breakdown (avg)")
                .font(.headline)

            HStack(spacing: 10) {
                MetricChip(title: "Above range", value: "\(sample.avgMinutesAboveRange) min", tint: .orange, systemImage: "arrow.up.right")
                MetricChip(title: "Below range", value: "\(sample.avgMinutesBelowRange) min", tint: .red, systemImage: "arrow.down.right")
                MetricChip(title: "In range", value: "\(max(0, 360 - sample.avgMinutesAboveRange - sample.avgMinutesBelowRange)) min", tint: .green, systemImage: "checkmark.circle.fill")
            }

            Text("Assumes a 6-hour night window (~360 minutes).")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Last 7 nights")
                    .font(.headline)
                Spacer()
                Text(mode == .nightsAboveRange ? "Minutes above range" : "Avg glucose")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            NightBarChart(
                labels: sample.dayLabels,
                values: mode == .nightsAboveRange
                ? sample.nightlyMinutesAboveRange.map(Double.init)
                : sample.nightlyAvg.map(Double.init),
                threshold: mode == .nightsAboveRange ? 45 : 140,
                barColor: AppTheme.primary
            )
            .frame(height: 150)

            Text(mode == .nightsAboveRange
                 ? "Highlighted bars suggest higher-than-usual time above range."
                 : "Highlighted bars suggest higher-than-usual overnight averages.")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var coachCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Coach suggestions (mock)")
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                AdviceLine(systemImage: "fork.knife", color: .orange, text: "Dinner spikes can carry into the night — try pairing carbs with protein + fiber.")
                AdviceLine(systemImage: "clock.fill", color: .blue, text: "Aim to finish dinner 2–3 hours before bed when possible.")
                AdviceLine(systemImage: "figure.walk", color: .green, text: "A short walk after dinner may reduce overnight highs.")
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct NighttimeCGMSample {
    let windowLabel: String
    let rangeLabel: String
    let nightsAboveRange: Int
    let totalNights: Int
    let avgNightGlucose: Int
    let avgMinutesAboveRange: Int
    let avgMinutesBelowRange: Int
    let nightlyAvg: [Int]
    let nightlyMinutesAboveRange: [Int]
    let dayLabels: [String]
}

private struct MetricChip: View {
    let title: String
    let value: String
    let tint: Color
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.caption).bold()
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Text(value)
                .font(.subheadline).bold()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct NightBarChart: View {
    let labels: [String]
    let values: [Double]
    let threshold: Double
    let barColor: Color

    var body: some View {
        GeometryReader { geo in
            let maxV = max(values.max() ?? 1, 1)
            let barWidth = max(10, (geo.size.width - CGFloat(values.count - 1) * 10) / CGFloat(values.count))
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(Array(values.enumerated()), id: \.offset) { idx, v in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(v >= threshold ? .orange : barColor.opacity(0.35))
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

#Preview {
    NavigationStack {
        NighttimeGlucoseMockView()
    }
}



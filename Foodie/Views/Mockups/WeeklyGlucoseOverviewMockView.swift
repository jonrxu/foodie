//
//  WeeklyGlucoseOverviewMockView.swift
//  Foodie
//
//  Simple survey mock: one clear weekly CGM graph with target range.
//

import SwiftUI

struct WeeklyGlucoseOverviewMockView: View {
    @Environment(\.dismiss) private var dismiss

    private let sample = CGMSimpleWeeklySample(
        timeInRangePercent: 78,
        targetTimeInRangePercent: 70,
        targetLow: 70,
        targetHigh: 180,
        dayLabels: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
        glucoseValues: [126, 158, 136, 172, 148, 132, 141]
    )

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                summaryCard
                weeklyGraphCard
                Spacer(minLength: 8)
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
                        .padding(.vertical, 11)
                        .background(AppTheme.primary)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                Spacer()
            }
            .padding(.vertical, 10)
            .background(Color(uiColor: .systemBackground))
        }
        .background(AppTheme.background)
        .navigationTitle("Weekly Glucose")
        .navigationBarTitleDisplayMode(.inline)
        .mockupsFullscreen()
        .navigationBarBackButtonHidden(true)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Goal time in range: \(sample.targetTimeInRangePercent)%+")
                .font(.headline)

            HStack {
                Text("This week")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(sample.timeInRangePercent)% in range")
                    .font(.title3).bold()
                    .foregroundStyle(AppTheme.primary)
            }

            ProgressView(value: Double(sample.timeInRangePercent), total: 100)
                .tint(AppTheme.primary)

            Text("Target glucose range: \(sample.targetLow)-\(sample.targetHigh) mg/dL")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var weeklyGraphCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Weekly fluctuations")
                .font(.headline)
            Text("Green area = target range")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            WeeklyGlucoseTrendChart(
                values: sample.glucoseValues,
                labels: sample.dayLabels,
                targetLow: sample.targetLow,
                targetHigh: sample.targetHigh
            )
            .frame(height: 350)
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct CGMSimpleWeeklySample {
    let timeInRangePercent: Int
    let targetTimeInRangePercent: Int
    let targetLow: Double
    let targetHigh: Double
    let dayLabels: [String]
    let glucoseValues: [Double]
}

private struct WeeklyGlucoseTrendChart: View {
    let values: [Double]
    let labels: [String]
    let targetLow: Double
    let targetHigh: Double

    private let minDisplayValue: Double = 50
    private let maxDisplayValue: Double = 220

    var body: some View {
        GeometryReader { geo in
            let height = geo.size.height
            let width = geo.size.width
            let topInset: CGFloat = 18
            let bottomInset: CGFloat = 34
            let chartHeight = max(1, height - topInset - bottomInset)
            let lowY = yPosition(for: targetLow, chartHeight: chartHeight, topInset: topInset)
            let highY = yPosition(for: targetHigh, chartHeight: chartHeight, topInset: topInset)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.green.opacity(0.14))
                    .frame(width: width, height: max(0, lowY - highY))
                    .offset(y: highY)

                Path { path in
                    path.move(to: CGPoint(x: 0, y: highY))
                    path.addLine(to: CGPoint(x: width, y: highY))
                    path.move(to: CGPoint(x: 0, y: lowY))
                    path.addLine(to: CGPoint(x: width, y: lowY))
                }
                .stroke(
                    Color.green.opacity(0.45),
                    style: StrokeStyle(lineWidth: 1, dash: [5, 5])
                )

                Path { path in
                    guard !values.isEmpty else { return }
                    path.move(to: CGPoint(
                        x: xPosition(for: 0, width: width),
                        y: yPosition(for: values[0], chartHeight: chartHeight, topInset: topInset)
                    ))
                    for idx in values.indices.dropFirst() {
                        path.addLine(to: CGPoint(
                            x: xPosition(for: idx, width: width),
                            y: yPosition(for: values[idx], chartHeight: chartHeight, topInset: topInset)
                        ))
                    }
                }
                .stroke(
                    AppTheme.primary,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )

                ForEach(values.indices, id: \.self) { idx in
                    Circle()
                        .fill(AppTheme.primary)
                        .frame(width: 8, height: 8)
                        .position(
                            x: xPosition(for: idx, width: width),
                            y: yPosition(for: values[idx], chartHeight: chartHeight, topInset: topInset)
                        )
                }

                ForEach(labels.indices, id: \.self) { idx in
                    Text(labels[idx])
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .position(x: xPosition(for: idx, width: width), y: height - 9)
                }
            }
        }
    }

    private func xPosition(for index: Int, width: CGFloat) -> CGFloat {
        guard values.count > 1 else { return width / 2 }
        return CGFloat(index) * (width / CGFloat(values.count - 1))
    }

    private func yPosition(for glucose: Double, chartHeight: CGFloat, topInset: CGFloat) -> CGFloat {
        let clamped = min(max(glucose, minDisplayValue), maxDisplayValue)
        let ratio = (clamped - minDisplayValue) / (maxDisplayValue - minDisplayValue)
        return topInset + (1 - CGFloat(ratio)) * chartHeight
    }
}

#Preview {
    NavigationStack {
        WeeklyGlucoseOverviewMockView()
    }
}

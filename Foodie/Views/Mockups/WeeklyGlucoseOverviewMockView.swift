//
//  WeeklyGlucoseOverviewMockView.swift
//  Foodie
//
//  Simple survey mock: one clear weekly CGM summary.
//

import SwiftUI

struct WeeklyGlucoseOverviewMockView: View {
    @Environment(\.dismiss) private var dismiss

    private let sample = CGMSimpleWeeklySample(
        timeInRangePercent: 82,
        targetTimeInRangePercent: 85,
        targetLow: 70,
        targetHigh: 180,
        dayLabels: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
        glucoseValues: [126, 160, 149, 176, 166, 154, 162]
    )

    private var isOnGoal: Bool {
        sample.timeInRangePercent >= sample.targetTimeInRangePercent
    }

    private var statusColor: Color {
        if isOnGoal { return .green }
        if sample.timeInRangePercent >= sample.targetTimeInRangePercent - 5 { return .green }
        return .orange
    }

    private var goalDelta: Int {
        sample.timeInRangePercent - sample.targetTimeInRangePercent
    }

    private var statusText: String {
        "Target: \(sample.targetTimeInRangePercent)%"
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                pageBackground
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    header
                    Spacer(minLength: 16)
                    summaryCard
                    Spacer(minLength: 14)
                    trendCard
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 62)
                .padding(.bottom, 24)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .mockupsFullscreen()
        .navigationBarBackButtonHidden(true)
        .onTapGesture {
            dismiss()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weekly glucose")
                .font(.system(size: 33, weight: .bold, design: .rounded))

            Text("What your CGM says in the last 7 days")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Time in range")
                        .font(.headline)
                }

                Spacer()

                Text(statusText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(statusColor.opacity(0.14))
                    .clipShape(Capsule())
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(sample.timeInRangePercent)%")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(statusColor)
                Text("this week")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            TimeInRangeBar(
                value: Double(sample.timeInRangePercent),
                goal: Double(sample.targetTimeInRangePercent),
                fillColor: statusColor
            )
            .frame(height: 14)

            Text("\(abs(goalDelta))% more to hit your weekly goal")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(statusColor)
        }
        .padding(16)
        .background(.white.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.blue.opacity(0.12), lineWidth: 1)
        )
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Weekly trend")
                    .font(.title3).bold()
                Spacer()
                Text("CGM")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            WeeklyGlucoseTrendChart(
                values: sample.glucoseValues,
                labels: sample.dayLabels,
                targetLow: sample.targetLow,
                targetHigh: sample.targetHigh
            )
            .frame(height: 276)
        }
        .padding(16)
        .background(.white.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.blue.opacity(0.12), lineWidth: 1)
        )
    }

    private var pageBackground: some View {
        ZStack {
            Color.white

            LinearGradient(
                colors: [
                    .white,
                    .white,
                    Color.blue.opacity(0.003),
                    Color.blue.opacity(0.012)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [Color.blue.opacity(0.012), Color.blue.opacity(0.0)],
                center: UnitPoint(x: 0.5, y: 0.8),
                startRadius: 60,
                endRadius: 540
            )
        }
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

private struct TimeInRangeBar: View {
    let value: Double
    let goal: Double
    let fillColor: Color

    var body: some View {
        GeometryReader { geo in
            let width = max(0, geo.size.width)
            let goalCap = max(goal, 1)
            let progressToGoal = min(max(value / goalCap, 0), 1)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.blue.opacity(0.12))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [fillColor.opacity(0.92), fillColor.opacity(0.72)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(10, width * CGFloat(progressToGoal)))
            }
            .clipShape(Capsule())
        }
    }
}

private struct WeeklyGlucoseTrendChart: View {
    let values: [Double]
    let labels: [String]
    let targetLow: Double
    let targetHigh: Double

    private let minDisplayValue: Double = 60
    private let maxDisplayValue: Double = 210

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let topInset: CGFloat = 12
            let bottomInset: CGFloat = 28
            let leftInset: CGFloat = 34
            let rightInset: CGFloat = 8
            let plotWidth = max(1, width - leftInset - rightInset)
            let plotHeight = max(1, height - topInset - bottomInset)

            let highY = yPosition(for: targetHigh, topInset: topInset, plotHeight: plotHeight)
            let lowY = yPosition(for: targetLow, topInset: topInset, plotHeight: plotHeight)
            let points = chartPoints(leftInset: leftInset, plotWidth: plotWidth, topInset: topInset, plotHeight: plotHeight)
            let bottomY = height - bottomInset

            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: leftInset, y: highY))
                    path.addLine(to: CGPoint(x: width - rightInset, y: highY))
                    path.move(to: CGPoint(x: leftInset, y: lowY))
                    path.addLine(to: CGPoint(x: width - rightInset, y: lowY))
                }
                .stroke(Color.green.opacity(0.42), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))

                Text("\(Int(targetHigh))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .position(x: 14, y: highY)

                Text("\(Int(targetLow))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .position(x: 14, y: lowY)

                smoothedAreaPath(points, bottomY: bottomY)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.12), Color.blue.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                smoothedPath(points)
                    .stroke(
                        LinearGradient(
                            colors: [AppTheme.primary.opacity(0.95), AppTheme.primary.opacity(0.84)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3.4, lineCap: .round, lineJoin: .round)
                    )

                VStack {
                    Spacer()
                    HStack {
                        ForEach(labels.indices, id: \.self) { index in
                            Text(labels[index])
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.leading, leftInset)
                    .padding(.trailing, rightInset)
                    .padding(.bottom, 2)
                }
            }
        }
    }

    private func chartPoints(leftInset: CGFloat, plotWidth: CGFloat, topInset: CGFloat, plotHeight: CGFloat) -> [CGPoint] {
        values.indices.map { index in
            CGPoint(
                x: xPosition(for: index, plotWidth: plotWidth) + leftInset,
                y: yPosition(for: values[index], topInset: topInset, plotHeight: plotHeight)
            )
        }
    }

    private func smoothedPath(_ points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)

        guard points.count > 1 else { return path }
        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let mid = CGPoint(x: (previous.x + current.x) / 2, y: (previous.y + current.y) / 2)
            path.addQuadCurve(to: mid, control: previous)
        }

        if let last = points.last, let secondLast = points.dropLast().last {
            path.addQuadCurve(to: last, control: secondLast)
        }
        return path
    }

    private func smoothedAreaPath(_ points: [CGPoint], bottomY: CGFloat) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: CGPoint(x: first.x, y: bottomY))
        path.addLine(to: first)

        if points.count > 1 {
            for index in 1..<points.count {
                let previous = points[index - 1]
                let current = points[index]
                let mid = CGPoint(x: (previous.x + current.x) / 2, y: (previous.y + current.y) / 2)
                path.addQuadCurve(to: mid, control: previous)
            }
            if let last = points.last, let secondLast = points.dropLast().last {
                path.addQuadCurve(to: last, control: secondLast)
                path.addLine(to: CGPoint(x: last.x, y: bottomY))
            }
        } else {
            path.addLine(to: CGPoint(x: first.x, y: bottomY))
        }

        path.closeSubpath()
        return path
    }

    private func xPosition(for index: Int, plotWidth: CGFloat) -> CGFloat {
        guard values.count > 1 else { return plotWidth / 2 }
        return CGFloat(index) * (plotWidth / CGFloat(values.count - 1))
    }

    private func yPosition(for glucose: Double, topInset: CGFloat, plotHeight: CGFloat) -> CGFloat {
        let clamped = min(max(glucose, minDisplayValue), maxDisplayValue)
        let ratio = (clamped - minDisplayValue) / (maxDisplayValue - minDisplayValue)
        return topInset + (1 - CGFloat(ratio)) * plotHeight
    }
}

#Preview {
    NavigationStack {
        WeeklyGlucoseOverviewMockView()
    }
}

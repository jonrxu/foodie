//
//  PlateFeedbackMockView.swift
//  Foodie
//
//  Sleek survey mock: smooth post-meal glucose trend + simple coach guidance.
//

import SwiftUI

struct PlateFeedbackMockView: View {
    @Environment(\.dismiss) private var dismiss

    private let impact = MealGlucoseImpact(
        withMeal: [
            GlucosePoint(minute: 0, glucose: 118),
            GlucosePoint(minute: 10, glucose: 132),
            GlucosePoint(minute: 20, glucose: 148),
            GlucosePoint(minute: 30, glucose: 156),
            GlucosePoint(minute: 42, glucose: 151),
            GlucosePoint(minute: 55, glucose: 145),
            GlucosePoint(minute: 68, glucose: 147),
            GlucosePoint(minute: 82, glucose: 137),
            GlucosePoint(minute: 96, glucose: 131),
            GlucosePoint(minute: 108, glucose: 125),
            GlucosePoint(minute: 120, glucose: 122)
        ],
        withoutMeal: [
            GlucosePoint(minute: 0, glucose: 118),
            GlucosePoint(minute: 24, glucose: 116.8),
            GlucosePoint(minute: 48, glucose: 115.7),
            GlucosePoint(minute: 72, glucose: 114.6),
            GlucosePoint(minute: 92, glucose: 114.9),
            GlucosePoint(minute: 108, glucose: 114.1),
            GlucosePoint(minute: 120, glucose: 113.6)
        ]
    )

    var body: some View {
        GeometryReader { geo in
            ZStack {
                pageBackground
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    header
                    Spacer(minLength: 18)
                    trendCard
                    Spacer(minLength: 26)
                    coachBubble
                    Spacer(minLength: 0)
                }
                .padding(.leading, 18)
                .padding(.trailing, 18)
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
            Text("Analyzing your meal")
                .font(.system(size: 33, weight: .bold, design: .rounded))

            Text("Estimated sugar response over the next 2 hours")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Your sugar trend")
                    .font(.title3).bold()
                Spacer()
                Text("2h estimate")
                    .font(.caption).bold()
                    .foregroundStyle(.blue.opacity(0.72))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color.blue.opacity(0.08))
                    .clipShape(Capsule())
            }

            GlucoseImpactChart(
                withMeal: impact.withMeal,
                withoutMeal: impact.withoutMeal
            )
            .frame(height: 214)
            .padding(.top, 10)
            .padding(.horizontal, 4)

            HStack(spacing: 16) {
                TrendLegendLine(color: .blue, style: .solid, text: "With this meal")
                TrendLegendLine(color: .blue.opacity(0.35), style: .dashed, text: "Without")
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, 2)
    }

    private var coachBubble: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.2))
                    .frame(width: 34, height: 34)
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.primary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("AI Coach")
                    .font(.caption).bold()
                    .foregroundStyle(.secondary)
                Text("Nice overall balance. You may see a short spike, then a cooldown. Next time, try swapping fries for a side salad to make the rise gentler.")
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(15)
            .background(.white.opacity(0.96))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.blue.opacity(0.14), lineWidth: 1)
            )
        }
        .padding(.leading, 2)
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
                center: UnitPoint(x: 0.5, y: 0.78),
                startRadius: 60,
                endRadius: 520
            )
        }
    }
}

private struct GlucosePoint {
    let minute: Double
    let glucose: Double
}

private struct MealGlucoseImpact {
    let withMeal: [GlucosePoint]
    let withoutMeal: [GlucosePoint]
}

private struct GlucoseImpactChart: View {
    let withMeal: [GlucosePoint]
    let withoutMeal: [GlucosePoint]

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let topInset: CGFloat = 12
            let bottomInset: CGFloat = 30
            let leftInset: CGFloat = 40
            let rightInset: CGFloat = 12
            let plotWidth = max(1, width - leftInset - rightInset)
            let plotHeight = max(1, height - topInset - bottomInset)
            let allPoints = withMeal + withoutMeal
            let rawMinGlucose = allPoints.map(\.glucose).min() ?? 100
            let rawMaxGlucose = allPoints.map(\.glucose).max() ?? 160
            let minGlucose = floor((rawMinGlucose - 8) / 10) * 10
            let maxGlucose = ceil((rawMaxGlucose + 8) / 10) * 10
            let maxMinute = max(allPoints.map(\.minute).max() ?? 120, 1)
            let yTicks = axisTicks(min: minGlucose, max: maxGlucose)
            let fadeFloorY = yPosition(
                for: minGlucose,
                minGlucose: minGlucose,
                maxGlucose: maxGlucose,
                topInset: topInset,
                plotHeight: plotHeight
            )

            let mealCurve = chartPoints(
                for: withMeal,
                maxMinute: maxMinute,
                leftInset: leftInset,
                plotWidth: plotWidth,
                minGlucose: minGlucose,
                maxGlucose: maxGlucose,
                topInset: topInset,
                plotHeight: plotHeight
            )
            let baselineCurve = chartPoints(
                for: withoutMeal,
                maxMinute: maxMinute,
                leftInset: leftInset,
                plotWidth: plotWidth,
                minGlucose: minGlucose,
                maxGlucose: maxGlucose,
                topInset: topInset,
                plotHeight: plotHeight
            )
            let bottomY = height - bottomInset

            ZStack {
                ForEach(yTicks, id: \.self) { tick in
                    let y = yPosition(
                        for: Double(tick),
                        minGlucose: minGlucose,
                        maxGlucose: maxGlucose,
                        topInset: topInset,
                        plotHeight: plotHeight
                    )

                    Path { path in
                        path.move(to: CGPoint(x: leftInset, y: y))
                        path.addLine(to: CGPoint(x: width - rightInset, y: y))
                    }
                    .stroke(Color.blue.opacity(0.1), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))

                    Text("\(tick)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .position(x: 18, y: y)
                }

                smoothedAreaPath(mealCurve, bottomY: fadeFloorY)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.13), Color.blue.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                smoothedPath(baselineCurve)
                    .stroke(
                        Color.blue.opacity(0.3),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [6, 5])
                    )

                smoothedPath(mealCurve)
                    .stroke(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.9), Color.blue.opacity(0.82)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3.4, lineCap: .round, lineJoin: .round)
                    )

                VStack {
                    Spacer()
                    HStack {
                        Text("Now")
                        Spacer()
                        Text("1h")
                        Spacer()
                        Text("2h")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.leading, leftInset)
                    .padding(.trailing, rightInset)
                    .padding(.bottom, 4)
                }
            }
        }
    }

    private func axisTicks(min: Double, max: Double) -> [Int] {
        let high = Int((max / 10).rounded(.up) * 10)
        let low = Int((min / 10).rounded(.down) * 10)
        let mid = Int((Double(high + low) / 2).rounded())
        return [high, mid, low]
    }

    private func chartPoints(
        for data: [GlucosePoint],
        maxMinute: Double,
        leftInset: CGFloat,
        plotWidth: CGFloat,
        minGlucose: Double,
        maxGlucose: Double,
        topInset: CGFloat,
        plotHeight: CGFloat
    ) -> [CGPoint] {
        data.map { point in
            CGPoint(
                x: xPosition(for: point.minute, maxMinute: maxMinute, width: plotWidth) + leftInset,
                y: yPosition(
                    for: point.glucose,
                    minGlucose: minGlucose,
                    maxGlucose: maxGlucose,
                    topInset: topInset,
                    plotHeight: plotHeight
                )
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

    private func xPosition(for minute: Double, maxMinute: Double, width: CGFloat) -> CGFloat {
        CGFloat(minute / maxMinute) * width
    }

    private func yPosition(
        for glucose: Double,
        minGlucose: Double,
        maxGlucose: Double,
        topInset: CGFloat,
        plotHeight: CGFloat
    ) -> CGFloat {
        let denominator = max(maxGlucose - minGlucose, 1)
        let ratio = (glucose - minGlucose) / denominator
        return topInset + (1 - CGFloat(ratio)) * plotHeight
    }
}

private enum TrendLegendStyle {
    case solid
    case dashed
}

private struct TrendLegendLine: View {
    let color: Color
    let style: TrendLegendStyle
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            lineSample
                .frame(width: 22, height: 6)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var lineSample: some View {
        switch style {
        case .solid:
            Capsule().fill(color)
        case .dashed:
            DashedLineShape()
                .stroke(color, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
        }
    }
}

private struct DashedLineShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

#Preview {
    NavigationStack {
        PlateFeedbackMockView()
    }
}

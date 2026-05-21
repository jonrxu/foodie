//
//  WeeklyGlucoseOverviewMockView.swift
//  Foodie
//
//  Simple survey mock: one clear weekly CGM summary.
//

import SwiftUI

struct WeeklyGlucoseOverviewMockView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedWindow: CGMDisplayWindow = .weekly

    private let summary: GlucoseSummary?
    private let cgmStatusLabel: String?
    private let errorMessage: String?
    private let isSyncing: Bool
    private let hideTabBar: Bool
    private let onSync: (() -> Void)?
    let onPlanMealsForNextWeek: (() -> Void)?

    init(summary: GlucoseSummary? = nil,
         cgmStatusLabel: String? = nil,
         errorMessage: String? = nil,
         isSyncing: Bool = false,
         hideTabBar: Bool = true,
         onSync: (() -> Void)? = nil,
         onPlanMealsForNextWeek: (() -> Void)? = nil) {
        self.summary = summary
        self.cgmStatusLabel = cgmStatusLabel
        self.errorMessage = errorMessage
        self.isSyncing = isSyncing
        self.hideTabBar = hideTabBar
        self.onSync = onSync
        self.onPlanMealsForNextWeek = onPlanMealsForNextWeek
    }

    private var sample: CGMDisplaySample {
        if let summary {
            return CGMDisplaySample(summary: summary, window: selectedWindow)
        }

        return .demo(window: selectedWindow)
    }

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
        ZStack {
            pageBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    Spacer(minLength: 16)
                    summaryCard
                    Spacer(minLength: 14)
                    trendCard
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 62)
                .padding(.bottom, hideTabBar ? 24 : 112)
                .contentShape(Rectangle())
                .onTapGesture {
                    dismiss()
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .modifier(PrototypeTabBarVisibilityModifier(hideTabBar: hideTabBar))
        .navigationBarBackButtonHidden(true)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Glucose overview")
                .font(.system(size: 33, weight: .bold, design: .rounded))

            Text(sample.headerSubtitle)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.secondary)

            if let cgmStatusLabel, !cgmStatusLabel.isEmpty {
                Text(cgmStatusLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.teal)
            }

            Picker("Range", selection: $selectedWindow) {
                ForEach(CGMDisplayWindow.allCases) { window in
                    Text(window.controlTitle).tag(window)
                }
            }
            .pickerStyle(.segmented)
            .padding(.top, 2)
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
                Text(sample.periodLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            TimeInRangeBar(
                value: Double(sample.timeInRangePercent),
                goal: Double(sample.targetTimeInRangePercent),
                fillColor: statusColor
            )
            .frame(height: 14)

            if let errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.red)
            } else if goalDelta >= 0 {
                Text("\(goalDelta)% above your \(sample.goalLabel)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(statusColor)
            } else {
                Text("\(abs(goalDelta))% more to hit your \(sample.goalLabel)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(statusColor)
            }

            if let onSync {
                Button(action: onSync) {
                    HStack(spacing: 8) {
                        if isSyncing {
                            ProgressView()
                                .tint(AppTheme.primary)
                        }
                        Text(isSyncing ? "Syncing Dexcom..." : "Sync Dexcom")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(uiColor: .tertiarySystemFill))
                    .foregroundStyle(.primary)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isSyncing)
            }
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
                Text(sample.trendTitle)
                    .font(.title3).bold()
                Spacer()
                Text(summary == nil ? "Demo" : "Dexcom")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if sample.hasAnyData {
                WeeklyGlucoseTrendChart(
                    values: sample.glucoseValues,
                    labels: sample.axisLabels,
                    targetLow: sample.targetLow,
                    targetHigh: sample.targetHigh
                )
                .frame(height: 276)
            } else {
                VStack(spacing: 10) {
                    Spacer()
                    Text("No glucose data yet")
                        .font(.headline.weight(.semibold))
                    Text("Once Dexcom readings are available, your trend will appear here")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 276)
            }
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

private enum CGMDisplayWindow: String, CaseIterable, Identifiable {
    case weekly
    case last24Hours

    var id: String { rawValue }

    var controlTitle: String {
        switch self {
        case .weekly:
            return "7d"
        case .last24Hours:
            return "24h"
        }
    }
}

private struct CGMDisplaySample {
    let timeInRangePercent: Int
    let targetTimeInRangePercent: Int
    let targetLow: Double
    let targetHigh: Double
    let periodLabel: String
    let goalLabel: String
    let trendTitle: String
    let headerSubtitle: String
    let axisLabels: [String]
    let glucoseValues: [Double?]

    var hasAnyData: Bool {
        glucoseValues.contains(where: { $0 != nil })
    }

    init(
        timeInRangePercent: Int,
        targetTimeInRangePercent: Int,
        targetLow: Double,
        targetHigh: Double,
        periodLabel: String,
        goalLabel: String,
        trendTitle: String,
        headerSubtitle: String,
        axisLabels: [String],
        glucoseValues: [Double?]
    ) {
        self.timeInRangePercent = timeInRangePercent
        self.targetTimeInRangePercent = targetTimeInRangePercent
        self.targetLow = targetLow
        self.targetHigh = targetHigh
        self.periodLabel = periodLabel
        self.goalLabel = goalLabel
        self.trendTitle = trendTitle
        self.headerSubtitle = headerSubtitle
        self.axisLabels = axisLabels
        self.glucoseValues = glucoseValues
    }

    static func demo(window: CGMDisplayWindow) -> CGMDisplaySample {
        switch window {
        case .weekly:
            return CGMDisplaySample(
                timeInRangePercent: 82,
                targetTimeInRangePercent: 85,
                targetLow: 70,
                targetHigh: 180,
                periodLabel: "this week",
                goalLabel: "weekly goal",
                trendTitle: "Weekly trend",
                headerSubtitle: "What your CGM says in the last 7 days",
                axisLabels: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
                glucoseValues: [
                    118, 121, 125, 132, 144, 152, 147, 139,
                    129, 124, 127, 136, 149, 162, 171, 164,
                    152, 143, 138, 145, 156, 169, 174, 166,
                    151, 140, 134, 129
                ]
            )
        case .last24Hours:
            return CGMDisplaySample(
                timeInRangePercent: 86,
                targetTimeInRangePercent: 85,
                targetLow: 70,
                targetHigh: 180,
                periodLabel: "last 24h",
                goalLabel: "24-hour goal",
                trendTitle: "Last 24 hours",
                headerSubtitle: "What your CGM says in the last 24 hours",
                axisLabels: ["12p", "4p", "8p", "12a", "4a", "8a", "12p"],
                glucoseValues: [118, 122, 126, 129, 135, 142, 150, 158, 166, 171, 164, 156, 148, 141, 137, 132, 126, 120, 115, 111, 108, 112, 119, 124]
            )
        }
    }

    init(summary: GlucoseSummary, window: CGMDisplayWindow) {
        switch window {
        case .weekly:
            self = CGMDisplaySample.makeWeeklySample(summary: summary)
        case .last24Hours:
            self = CGMDisplaySample.makeLast24HourSample(summary: summary)
        }
    }

    private static func makeWeeklySample(summary: GlucoseSummary) -> CGMDisplaySample {
        let calendar = Calendar.current
        let endDay = calendar.startOfDay(for: summary.endDate)
        let startDay = calendar.date(byAdding: .day, value: -6, to: endDay) ?? endDay

        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        let labels = (0..<7).map { offset in
            formatter.string(from: calendar.date(byAdding: .day, value: offset, to: startDay) ?? startDay)
        }
        let values = bucketAverages(
            readings: summary.readings.sorted { $0.timestamp < $1.timestamp },
            start: startDay,
            bucketDuration: 2 * 60 * 60,
            bucketCount: 84
        )

        return CGMDisplaySample(
            timeInRangePercent: timeInRangePercent(
                readings: summary.readings,
                targetLow: summary.targetLowMgdl,
                targetHigh: summary.targetHighMgdl,
                fallback: summary.timeInRangePercent
            ),
            targetTimeInRangePercent: 85,
            targetLow: Double(summary.targetLowMgdl),
            targetHigh: Double(summary.targetHighMgdl),
            periodLabel: "this week",
            goalLabel: "weekly goal",
            trendTitle: "Weekly trend",
            headerSubtitle: "What your CGM says in the last 7 days",
            axisLabels: labels,
            glucoseValues: values.isEmpty ? Array(repeating: nil, count: 84) : values
        )
    }

    private static func makeLast24HourSample(summary: GlucoseSummary) -> CGMDisplaySample {
        let sortedReadings = summary.readings.sorted { $0.timestamp < $1.timestamp }
        let anchor = sortedReadings.last?.timestamp ?? summary.endDate
        let start = anchor.addingTimeInterval(-24 * 60 * 60)
        let windowReadings = sortedReadings.filter { reading in
            reading.timestamp >= start && reading.timestamp <= anchor
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        formatter.amSymbol = "a"
        formatter.pmSymbol = "p"

        let labels = stride(from: 0, through: 24, by: 4).map { hourOffset in
            formatter.string(from: start.addingTimeInterval(Double(hourOffset) * 60 * 60)).lowercased()
        }
        let values = bucketAverages(
            readings: windowReadings,
            start: start,
            bucketDuration: 60 * 60,
            bucketCount: 24
        )

        return CGMDisplaySample(
            timeInRangePercent: timeInRangePercent(
                readings: windowReadings,
                targetLow: summary.targetLowMgdl,
                targetHigh: summary.targetHighMgdl,
                fallback: summary.timeInRangePercent
            ),
            targetTimeInRangePercent: 85,
            targetLow: Double(summary.targetLowMgdl),
            targetHigh: Double(summary.targetHighMgdl),
            periodLabel: "last 24h",
            goalLabel: "24-hour goal",
            trendTitle: "Last 24 hours",
            headerSubtitle: "What your CGM says in the last 24 hours",
            axisLabels: labels,
            glucoseValues: values
        )
    }

    private static func bucketAverages(
        readings: [GlucoseReading],
        start: Date,
        bucketDuration: TimeInterval,
        bucketCount: Int
    ) -> [Double?] {
        guard bucketCount > 0 else { return [] }

        let sortedReadings = readings.sorted { $0.timestamp < $1.timestamp }
        var values: [Double?] = []
        values.reserveCapacity(bucketCount)
        var index = 0

        for bucketIndex in 0..<bucketCount {
            let bucketStart = start.addingTimeInterval(Double(bucketIndex) * bucketDuration)
            let bucketEnd = bucketStart.addingTimeInterval(bucketDuration)
            var bucketValues: [Int] = []

            while index < sortedReadings.count, sortedReadings[index].timestamp < bucketStart {
                index += 1
            }
            var scanIndex = index
            while scanIndex < sortedReadings.count, sortedReadings[scanIndex].timestamp < bucketEnd {
                bucketValues.append(sortedReadings[scanIndex].valueMgdl)
                scanIndex += 1
            }
            index = scanIndex

            if bucketValues.isEmpty {
                values.append(nil)
            } else {
                let average = bucketValues.reduce(0, +)
                values.append(Double(average) / Double(bucketValues.count))
            }
        }

        return values
    }

    private static func timeInRangePercent(
        readings: [GlucoseReading],
        targetLow: Int,
        targetHigh: Int,
        fallback: Int?
    ) -> Int {
        guard !readings.isEmpty else { return fallback ?? 0 }
        let values = readings.map(\.valueMgdl)
        let inRange = values.filter { value in
            value >= targetLow && value <= targetHigh
        }
        return Int(round((Double(inRange.count) / Double(values.count)) * 100))
    }
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
    let values: [Double?]
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
            let pointSegments = chartSegments(leftInset: leftInset, plotWidth: plotWidth, topInset: topInset, plotHeight: plotHeight)
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

                smoothedAreaPath(pointSegments, bottomY: bottomY)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.12), Color.blue.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                smoothedPath(pointSegments)
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
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
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

    private func chartSegments(leftInset: CGFloat, plotWidth: CGFloat, topInset: CGFloat, plotHeight: CGFloat) -> [[CGPoint]] {
        var segments: [[CGPoint]] = []
        var current: [CGPoint] = []

        for index in values.indices {
            guard let value = values[index] else {
                if !current.isEmpty {
                    segments.append(current)
                    current = []
                }
                continue
            }

            current.append(
                CGPoint(
                    x: xPosition(for: index, plotWidth: plotWidth) + leftInset,
                    y: yPosition(for: value, topInset: topInset, plotHeight: plotHeight)
                )
            )
        }

        if !current.isEmpty {
            segments.append(current)
        }

        return segments
    }

    private func smoothedPath(_ segments: [[CGPoint]]) -> Path {
        var path = Path()
        for points in segments {
            guard let first = points.first else { continue }
            path.move(to: first)

            guard points.count > 1 else { continue }
            for index in 1..<points.count {
                let previous = points[index - 1]
                let current = points[index]
                let mid = CGPoint(x: (previous.x + current.x) / 2, y: (previous.y + current.y) / 2)
                path.addQuadCurve(to: mid, control: previous)
            }
            if let last = points.last, let secondLast = points.dropLast().last {
                path.addQuadCurve(to: last, control: secondLast)
            }
        }
        return path
    }

    private func smoothedAreaPath(_ segments: [[CGPoint]], bottomY: CGFloat) -> Path {
        var path = Path()
        for points in segments {
            guard let first = points.first else { continue }
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
        }
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

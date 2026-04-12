//
//  PrototypeMealFeedbackView.swift
//  Foodie
//

import SwiftUI

struct PrototypeMealFeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var mealFlowViewModel: PrototypeMealFlowViewModel

    @State private var showCoachFeedback = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                PrototypeMealPageBackground()
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                        Spacer(minLength: 10)
                        mealCard
                        Spacer(minLength: 10)
                        trendCard
                        Spacer(minLength: 14)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dismiss()
                    }

                    nextButton
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 18)
                .padding(.top, 62)
                .padding(.bottom, 24)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .mockupsFullscreen()
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showCoachFeedback) {
            PrototypeMealCoachFeedbackView()
        }
        .task {
            await mealFlowViewModel.bootstrapIfNeeded()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(currentInsight?.feedback.headline ?? "Feedback on your meal")
                .font(.system(size: 33, weight: .bold, design: .rounded))

            Text("Quick look at your next 2 hours")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private var mealCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            mealImage

            Text(currentInsight?.mealLog.summary ?? "No meal logged yet")
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var mealImage: some View {
        let cameraOverlay = ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .frame(width: 30, height: 30)
            Image(systemName: "camera.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.primary)
        }
        .padding(8)

        if let imageName = currentInsight?.mealImageName {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 214)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(alignment: .topTrailing) { cameraOverlay }
        } else if let captured = mealFlowViewModel.capturedMealImage {
            Image(uiImage: captured)
                .resizable()
                .scaledToFill()
                .frame(width: 214, height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(alignment: .topTrailing) { cameraOverlay }
        }
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(currentInsight?.feedback.mode == .measured ? "Glucose after this meal" : "Predicted glucose spike")
                    .font(.title3).bold()
                Spacer()
                Text(currentInsight?.feedback.mode == .measured ? "Measured" : "2h estimate")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            PrototypeGlucoseImpactChart(
                withMeal: currentInsight?.impact.withMeal ?? [],
                withoutMeal: currentInsight?.impact.withoutMeal ?? []
            )
            .frame(height: 176)
            .padding(.top, 4)

            HStack(spacing: 16) {
                PrototypeTrendLegendLine(color: .blue, style: .solid, text: currentInsight?.feedback.mode == .measured ? "Observed" : "With this meal")
                PrototypeTrendLegendLine(color: .blue.opacity(0.35), style: .dashed, text: "Without")
            }
            .frame(maxWidth: .infinity, alignment: .center)

            if let summary = currentInsight?.feedback.summary {
                Text(summary)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
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

    private var nextButton: some View {
        HStack {
            Spacer()
            Button {
                showCoachFeedback = true
            } label: {
                Text("See AI coach feedback")
                    .font(.headline.weight(.semibold))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 11)
                    .foregroundStyle(.white)
                    .background(AppTheme.primary)
                    .clipShape(Capsule())
            }
            .disabled(currentInsight == nil)
            Spacer()
        }
    }

    private var currentInsight: MealInsightContext? {
        mealFlowViewModel.latestInsight
    }
}

struct PrototypeMealCoachFeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var mealFlowViewModel: PrototypeMealFlowViewModel

    @State private var showCart = false
    @State private var isHandingOffToCart = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                PrototypeMealPageBackground()
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                        Spacer(minLength: 12)
                        coachCard
                        Spacer(minLength: 14)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dismiss()
                    }

                    addToCartButton
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 18)
                .padding(.top, 62)
                .padding(.bottom, 24)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .mockupsFullscreen()
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showCart) {
            PrototypeShoppingCartView()
        }
        .task {
            await mealFlowViewModel.bootstrapIfNeeded()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AI coach feedback")
                .font(.system(size: 36, weight: .bold, design: .rounded))

            Text("Simple tips for your next meal")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private var coachCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(AppTheme.primary.opacity(0.2))
                        .frame(width: 30, height: 30)
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.primary)
                }

                Text("AI Coach")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
            }

            Text(currentInsight?.feedback.coachMessage ?? "Log a meal to see feedback.")
                .font(.title3)
                .foregroundStyle(.primary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            if let swap = currentInsight?.feedback.suggestedSwap {
                Text("Try this next time: \(swap).")
                    .font(.title3)
                    .foregroundStyle(.primary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }

            if let suggestionImageName = currentInsight?.suggestionImageName {
                HStack {
                    Spacer(minLength: 0)
                    Image(suggestionImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 242)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.black.opacity(0.08), lineWidth: 1)
                        )
                    Spacer(minLength: 0)
                }
                .padding(.top, 2)
            }
        }
        .padding(20)
        .background(.white.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.blue.opacity(0.14), lineWidth: 1)
        )
    }

    private var addToCartButton: some View {
        HStack {
            Spacer()
            Button {
                Task {
                    guard !isHandingOffToCart else { return }
                    await MainActor.run {
                        isHandingOffToCart = true
                    }
                    let didCreate = await mealFlowViewModel.addSuggestedIngredientsToCart()
                    if didCreate {
                        try? await Task.sleep(for: .milliseconds(750))
                        await MainActor.run {
                            showCart = true
                        }
                    } else {
                        await MainActor.run {
                            isHandingOffToCart = false
                        }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if mealFlowViewModel.isCreatingCart || isHandingOffToCart {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    }
                    Text((mealFlowViewModel.isCreatingCart || isHandingOffToCart) ? "Adding..." : "Add ingredients to my cart")
                        .font(.headline.weight(.semibold))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 11)
                .foregroundStyle(.white)
                .background(AppTheme.primary)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(mealFlowViewModel.isCreatingCart || isHandingOffToCart || currentInsight == nil)
            Spacer()
        }
    }

    private var currentInsight: MealInsightContext? {
        mealFlowViewModel.latestInsight
    }
}

private struct PrototypeMealPageBackground: View {
    var body: some View {
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

private struct PrototypeGlucoseImpactChart: View {
    let withMeal: [MealImpactPoint]
    let withoutMeal: [MealImpactPoint]

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
        for data: [MealImpactPoint],
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

private enum PrototypeTrendLegendStyle {
    case solid
    case dashed
}

private struct PrototypeTrendLegendLine: View {
    let color: Color
    let style: PrototypeTrendLegendStyle
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
            PrototypeDashedLineShape()
                .stroke(color, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
        }
    }
}

private struct PrototypeDashedLineShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

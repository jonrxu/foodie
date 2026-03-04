//
//  PlateFeedbackMockView.swift
//  Foodie
//
//  Mockup 2 split into two screens: glucose prediction, then AI coach advice.
//

import SwiftUI

struct PlateFeedbackMockView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showCoachFeedback = false
    @State private var showCart = false
    let onAddIngredientsToCart: (() -> Void)?

    init(onAddIngredientsToCart: (() -> Void)? = nil) {
        self.onAddIngredientsToCart = onAddIngredientsToCart
    }

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
                MockPageBackground()
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                        Spacer(minLength: 10)
                        loggedMealPhotoCard
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
            PlateCoachFeedbackMockView(
                onAddIngredientsToCart: {
                    if let onAddIngredientsToCart {
                        onAddIngredientsToCart()
                    } else {
                        showCart = true
                    }
                }
            )
        }
        .navigationDestination(isPresented: $showCart) {
            ShoppingCartMockView()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Feedback on your meal")
                .font(.system(size: 33, weight: .bold, design: .rounded))

            Text("Quick look at your next 2 hours")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private var loggedMealPhotoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image("chickenandfries")
                .resizable()
                .scaledToFit()
                .frame(width: 214)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(alignment: .topTrailing) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Color.white.opacity(0.92))
                            .frame(width: 30, height: 30)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.primary)
                    }
                    .padding(8)
                }

            Text("Chicken and fries")
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Predicted glucose spike")
                    .font(.title3).bold()
                Spacer()
                Text("2h estimate")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            GlucoseImpactChart(
                withMeal: impact.withMeal,
                withoutMeal: impact.withoutMeal
            )
            .frame(height: 176)
            .padding(.top, 4)

            HStack(spacing: 16) {
                TrendLegendLine(color: .blue, style: .solid, text: "With this meal")
                TrendLegendLine(color: .blue.opacity(0.35), style: .dashed, text: "Without")
            }
            .frame(maxWidth: .infinity, alignment: .center)
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
            Spacer()
        }
    }
}

struct PlateCoachFeedbackMockView: View {
    @Environment(\.dismiss) private var dismiss
    let onAddIngredientsToCart: (() -> Void)?
    @State private var isAddingToCart = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                MockPageBackground()
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

            Text("This meal is nicely balanced. You may see a short rise in your blood sugar, followed by a steady decrease.")
                .font(.title3)
                .foregroundStyle(.primary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Text("Try this next time: swap fries for a side salad.")
                .font(.title3)
                .foregroundStyle(.primary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)

            HStack {
                Spacer(minLength: 0)
                Image("chickenandsalad")
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
                if isAddingToCart { return }
                isAddingToCart = true

                // Demo affordance: brief loading before handing off to cart.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                    if let onAddIngredientsToCart {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            onAddIngredientsToCart()
                        }
                    } else {
                        dismiss()
                    }
                    isAddingToCart = false
                }
            } label: {
                HStack(spacing: 8) {
                    if isAddingToCart {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    }
                    Text(isAddingToCart ? "Adding..." : "Add ingredients to my cart")
                        .font(.headline.weight(.semibold))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 11)
                .foregroundStyle(.white)
                .background(AppTheme.primary)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isAddingToCart)
            Spacer()
        }
    }
}

private struct MockPageBackground: View {
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

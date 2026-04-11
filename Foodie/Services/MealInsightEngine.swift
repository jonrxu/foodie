//
//  MealInsightEngine.swift
//  Foodie
//

import Foundation

struct MealImpactPoint: Codable, Hashable {
    let minute: Double
    let glucose: Double
}

struct MealImpactChartData: Codable, Hashable {
    let withMeal: [MealImpactPoint]
    let withoutMeal: [MealImpactPoint]
}

struct MealInsightContext: Hashable {
    let mealLog: MealLog
    let mealImageName: String?
    let suggestionImageName: String?
    let feedback: MealFeedback
    let spikeEvent: SpikeEvent?
    let impact: MealImpactChartData
    let suggestedCartItems: [CartItem]
}

struct MealInsightEngine {
    func createMealLog(for mode: FoodLoggingMode, using readings: [GlucoseReading]) -> MealLog {
        let template = template(for: mode)
        let loggedAt = alignedMealTime(using: readings)

        return MealLog(
            loggedAt: loggedAt,
            source: template.source,
            summary: template.summary,
            rawInput: template.rawInput,
            assets: template.assetName.map {
                [MealAsset(kind: .photo, localIdentifier: $0, mimeType: "image/jpeg", previewText: template.summary)]
            } ?? [],
            analysis: MealAnalysis(
                mealType: template.mealType,
                estimatedCalories: template.calories,
                confidence: 0.9,
                nutrition: template.nutrition,
                healthIndex: template.healthIndex,
                healthLevel: template.healthLevel,
                healthTags: template.healthTags,
                highlights: template.highlights
            )
        )
    }

    func buildInsight(for mealLog: MealLog, readings: [GlucoseReading]) -> MealInsightContext {
        let template = template(for: mealLog)
        let sortedReadings = readings.sorted(by: { $0.timestamp < $1.timestamp })

        if let measured = measuredInsight(for: mealLog, template: template, readings: sortedReadings) {
            return measured
        }

        return predictedInsight(for: mealLog, template: template, readings: sortedReadings)
    }

    private func measuredInsight(for mealLog: MealLog,
                                 template: MealInsightTemplate,
                                 readings: [GlucoseReading]) -> MealInsightContext? {
        let baselineWindowStart = mealLog.loggedAt.addingTimeInterval(-30 * 60)
        let measurementWindowEnd = mealLog.loggedAt.addingTimeInterval(2 * 60 * 60)

        let baselineReadings = readings
            .filter { $0.timestamp >= baselineWindowStart && $0.timestamp < mealLog.loggedAt }
            .suffix(3)
        let postMealReadings = readings
            .filter { $0.timestamp >= mealLog.loggedAt && $0.timestamp <= measurementWindowEnd }

        guard baselineReadings.count >= 2, postMealReadings.count >= 4 else {
            return nil
        }

        let baseline = baselineReadings.map(\.valueMgdl).map(Double.init).reduce(0, +) / Double(baselineReadings.count)
        guard let peakReading = postMealReadings.max(by: { $0.valueMgdl < $1.valueMgdl }) else {
            return nil
        }

        let peak = Double(peakReading.valueMgdl)
        let delta = max(peak - baseline, 0)
        let peakMinutes = max(Int(peakReading.timestamp.timeIntervalSince(mealLog.loggedAt) / 60), 0)
        let returnReading = postMealReadings.first { reading in
            reading.timestamp > peakReading.timestamp && Double(reading.valueMgdl) <= min(180, baseline + 8)
        }
        let returnMinutes = returnReading.map { max(Int($0.timestamp.timeIntervalSince(mealLog.loggedAt) / 60), 0) }
        let confidence = min(0.95, 0.45 + (Double(postMealReadings.count) / 20) + min(delta, 50) / 100)

        let spikeEvent = SpikeEvent(
            mealLogID: mealLog.id,
            eventKind: .measured,
            startedAt: mealLog.loggedAt,
            peakAt: peakReading.timestamp,
            resolvedAt: returnReading?.timestamp,
            confidence: confidence,
            metrics: SpikeMetrics(
                baselineMgdl: baseline,
                peakMgdl: peak,
                deltaMgdl: delta,
                timeToPeakMinutes: peakMinutes,
                returnToRangeMinutes: returnMinutes
            ),
            notes: measuredNotes(delta: delta, baseline: baseline, template: template)
        )

        let feedback = MealFeedback(
            mealLogID: mealLog.id,
            mode: .measured,
            headline: "Feedback on your meal",
            summary: measuredSummary(delta: delta),
            coachMessage: measuredCoachMessage(delta: delta, template: template),
            suggestedSwap: template.suggestedSwap,
            linkedSpikeEventID: spikeEvent.id,
            suggestedCartItems: template.cartItems.map(\.name)
        )

        let withMeal = postMealReadings.map {
            MealImpactPoint(
                minute: max($0.timestamp.timeIntervalSince(mealLog.loggedAt) / 60, 0),
                glucose: Double($0.valueMgdl)
            )
        }
        let withoutMeal = baselineSeries(startingAt: baseline)

        return MealInsightContext(
            mealLog: mealLog,
            mealImageName: template.assetName,
            suggestionImageName: template.suggestionImageName,
            feedback: feedback,
            spikeEvent: spikeEvent,
            impact: MealImpactChartData(withMeal: withMeal, withoutMeal: withoutMeal),
            suggestedCartItems: template.cartItems
        )
    }

    private func predictedInsight(for mealLog: MealLog,
                                  template: MealInsightTemplate,
                                  readings: [GlucoseReading]) -> MealInsightContext {
        let baseline = Double(readings.last?.valueMgdl ?? 118)
        let carbs = mealLog.analysis?.nutrition?.totals.carbohydrateGrams ?? template.nutrition.totals.carbohydrateGrams ?? 45
        let addedSugar = mealLog.analysis?.nutrition?.totals.addedSugarGrams ?? template.nutrition.totals.addedSugarGrams ?? 0
        let fiber = mealLog.analysis?.nutrition?.totals.fiberGrams ?? template.nutrition.totals.fiberGrams ?? 0
        let protein = mealLog.analysis?.nutrition?.totals.proteinGrams ?? template.nutrition.totals.proteinGrams ?? 0

        var delta = 16.0
        delta += min(max((carbs - 35) * 0.45, 0), 18)
        delta += min(max(addedSugar * 0.7, 0), 12)
        delta -= min(max(fiber * 0.8, 0), 8)
        delta -= min(max((protein - 20) * 0.18, 0), 5)
        delta += keywordAdjustment(for: mealLog.summary)
        delta = min(max(delta, 10), 48)

        let peak = baseline + delta
        let timeToPeak = delta > 28 ? 36 : 42

        let spikeEvent = SpikeEvent(
            mealLogID: mealLog.id,
            eventKind: .predicted,
            startedAt: mealLog.loggedAt,
            confidence: 0.64,
            metrics: SpikeMetrics(
                baselineMgdl: baseline,
                peakMgdl: peak,
                deltaMgdl: delta,
                timeToPeakMinutes: timeToPeak,
                returnToRangeMinutes: 115
            ),
            notes: predictedNotes(delta: delta, template: template)
        )

        let feedback = MealFeedback(
            mealLogID: mealLog.id,
            mode: .predicted,
            headline: "Feedback on your meal",
            summary: predictedSummary(delta: delta),
            coachMessage: predictedCoachMessage(delta: delta, template: template),
            suggestedSwap: template.suggestedSwap,
            linkedSpikeEventID: spikeEvent.id,
            suggestedCartItems: template.cartItems.map(\.name)
        )

        let withMeal = predictedSeries(baseline: baseline, peak: peak)
        let withoutMeal = baselineSeries(startingAt: baseline)

        return MealInsightContext(
            mealLog: mealLog,
            mealImageName: template.assetName,
            suggestionImageName: template.suggestionImageName,
            feedback: feedback,
            spikeEvent: spikeEvent,
            impact: MealImpactChartData(withMeal: withMeal, withoutMeal: withoutMeal),
            suggestedCartItems: template.cartItems
        )
    }

    private func alignedMealTime(using readings: [GlucoseReading]) -> Date {
        let sorted = readings.sorted(by: { $0.timestamp < $1.timestamp })
        guard let latest = sorted.last?.timestamp else {
            return Date()
        }
        return min(Date(), latest.addingTimeInterval(-2 * 60 * 60))
    }

    private func baselineSeries(startingAt baseline: Double) -> [MealImpactPoint] {
        [
            MealImpactPoint(minute: 0, glucose: baseline),
            MealImpactPoint(minute: 30, glucose: baseline - 1.2),
            MealImpactPoint(minute: 60, glucose: baseline - 2.2),
            MealImpactPoint(minute: 90, glucose: baseline - 3.1),
            MealImpactPoint(minute: 120, glucose: baseline - 4.0)
        ]
    }

    private func predictedSeries(baseline: Double, peak: Double) -> [MealImpactPoint] {
        [
            MealImpactPoint(minute: 0, glucose: baseline),
            MealImpactPoint(minute: 15, glucose: baseline + (peak - baseline) * 0.38),
            MealImpactPoint(minute: 32, glucose: peak - 1.5),
            MealImpactPoint(minute: 48, glucose: peak),
            MealImpactPoint(minute: 68, glucose: baseline + (peak - baseline) * 0.62),
            MealImpactPoint(minute: 92, glucose: baseline + (peak - baseline) * 0.34),
            MealImpactPoint(minute: 120, glucose: baseline + (peak - baseline) * 0.12)
        ]
    }

    private func measuredSummary(delta: Double) -> String {
        switch delta {
        case ..<15:
            return "Your CGM stayed fairly steady after this meal"
        case ..<30:
            return "Your CGM showed a moderate rise, then a steady cooldown"
        default:
            return "Your CGM showed a sharper rise after this meal"
        }
    }

    private func measuredCoachMessage(delta: Double, template: MealInsightTemplate) -> String {
        switch delta {
        case ..<15:
            return "This meal stayed relatively steady on your CGM. Keeping the protein and swapping in a little more produce can help you stay in range."
        case ..<30:
            return "This meal caused a moderate glucose rise. A simpler carb swap can make the rise gentler next time."
        default:
            return "This meal pushed your glucose up more than ideal. A lighter starch choice would likely make the next rise much easier to manage."
        }
    }

    private func predictedSummary(delta: Double) -> String {
        switch delta {
        case ..<18:
            return "You may see a small rise, then a steady decrease"
        case ..<32:
            return "You may see a short rise, followed by a steady decrease"
        default:
            return "You may see a stronger rise before your glucose cools down"
        }
    }

    private func predictedCoachMessage(delta: Double, template: MealInsightTemplate) -> String {
        switch delta {
        case ..<18:
            return "This meal looks fairly balanced. Keeping the protein and vegetables in place should help keep the rise modest."
        case ..<32:
            return "This meal is nicely balanced. You may see a short rise in your blood sugar, followed by a steady decrease."
        default:
            return "This meal may raise your blood sugar more than ideal. One simple food swap could make the rise gentler next time."
        }
    }

    private func measuredNotes(delta: Double, baseline: Double, template: MealInsightTemplate) -> [String] {
        [
            delta >= 30 ? "Spike rose above the usual target range." : "Glucose stayed closer to the target range.",
            "Baseline was about \(Int(baseline.rounded())) mg/dL before the meal."
        ]
    }

    private func predictedNotes(delta: Double, template: MealInsightTemplate) -> [String] {
        [
            "Estimate based on recent glucose level and meal composition.",
            delta >= 30 ? "Higher-carb items likely drive most of the rise." : "Protein and fiber should help soften the rise."
        ]
    }

    private func keywordAdjustment(for summary: String) -> Double {
        let normalized = summary.lowercased()
        var adjustment = 0.0

        if normalized.contains("fries") { adjustment += 7 }
        if normalized.contains("soda") { adjustment += 10 }
        if normalized.contains("rice") { adjustment += 8 }
        if normalized.contains("burger") { adjustment += 6 }
        if normalized.contains("salad") { adjustment -= 6 }
        if normalized.contains("grilled") { adjustment -= 3 }

        return adjustment
    }

    private func template(for mode: FoodLoggingMode) -> MealInsightTemplate {
        switch mode {
        case .takePhoto:
            return MealInsightTemplate(
                source: .photo,
                mealType: .lunch,
                summary: "Chicken and fries",
                rawInput: "Captured meal photo",
                assetName: "chickenandfries",
                suggestionImageName: "chickenandsalad",
                calories: 640,
                healthIndex: 71,
                healthLevel: "Balanced",
                healthTags: ["Protein", "Carbs"],
                highlights: ["Protein helps steady the rise", "Fries add most of the starch"],
                nutrition: mealTotals(calories: 640, protein: 35, carbs: 54, fat: 24, fiber: 4, sugar: 3),
                suggestedSwap: "Swap fries for a side salad",
                cartItems: recommendedProduceAndProtein()
            )
        case .voiceLog:
            return MealInsightTemplate(
                source: .voice,
                mealType: .lunch,
                summary: "Chicken sandwich and fries",
                rawInput: "Voice log: chicken sandwich and fries",
                assetName: "chickenandfries",
                suggestionImageName: "chickenandsalad",
                calories: 690,
                healthIndex: 65,
                healthLevel: "Needs a lighter carb",
                healthTags: ["Protein", "Carbs"],
                highlights: ["Bread and fries raise the carb load", "Protein helps with fullness"],
                nutrition: mealTotals(calories: 690, protein: 33, carbs: 62, fat: 26, fiber: 4, sugar: 4),
                suggestedSwap: "Swap fries for a side salad",
                cartItems: recommendedProduceAndProtein()
            )
        case .barcodeScan:
            return MealInsightTemplate(
                source: .barcode,
                mealType: .snack,
                summary: "Packaged meal with fries",
                rawInput: "Barcode scan meal",
                assetName: "chickenandfries",
                suggestionImageName: "chickenandsalad",
                calories: 610,
                healthIndex: 60,
                healthLevel: "Higher processed carbs",
                healthTags: ["Convenience meal"],
                highlights: ["Packaged starches may raise glucose faster"],
                nutrition: mealTotals(calories: 610, protein: 27, carbs: 58, fat: 23, fiber: 3, sugar: 5),
                suggestedSwap: "Swap fries for a side salad",
                cartItems: recommendedProduceAndProtein()
            )
        case .textLog:
            return MealInsightTemplate(
                source: .text,
                mealType: .dinner,
                summary: "Burger, fries, and soda",
                rawInput: "Text log: burger, fries, and soda",
                assetName: "chickenandfries",
                suggestionImageName: "chickenandsalad",
                calories: 860,
                healthIndex: 52,
                healthLevel: "Higher sugar load",
                healthTags: ["Higher sugar", "Higher carbs"],
                highlights: ["Soda and fries push the rise higher"],
                nutrition: mealTotals(calories: 860, protein: 29, carbs: 88, fat: 34, fiber: 4, sugar: 24),
                suggestedSwap: "Swap soda for water",
                cartItems: [
                    CartItem(name: "Sparkling water", category: "Beverage", quantity: "1 pack"),
                    CartItem(name: "Chicken breast", category: "Protein", quantity: "1.5 lb"),
                    CartItem(name: "Mixed greens", category: "Produce", quantity: "1 box"),
                    CartItem(name: "Cherry tomatoes", category: "Produce", quantity: "1 pint"),
                    CartItem(name: "Whole-grain bread", category: "Carbs", quantity: "1 loaf")
                ]
            )
        }
    }

    private func template(for mealLog: MealLog) -> MealInsightTemplate {
        switch mealLog.source {
        case .voice:
            return template(for: .voiceLog)
        case .text:
            return template(for: .textLog)
        case .barcode:
            return template(for: .barcodeScan)
        case .photo, .manual, .imported, .unknown:
            return template(for: .takePhoto)
        }
    }

    private func mealTotals(calories: Double,
                            protein: Double,
                            carbs: Double,
                            fat: Double,
                            fiber: Double,
                            sugar: Double) -> NutritionBreakdown {
        NutritionBreakdown(
            totals: NutritionBreakdown.Totals(
                calories: calories,
                proteinGrams: protein,
                carbohydrateGrams: carbs,
                fatGrams: fat,
                fiberGrams: fiber,
                addedSugarGrams: sugar
            )
        )
    }

    private func recommendedProduceAndProtein() -> [CartItem] {
        [
            CartItem(name: "Mixed greens", category: "Produce", quantity: "1 box"),
            CartItem(name: "Cherry tomatoes", category: "Produce", quantity: "1 pint"),
            CartItem(name: "Cucumbers", category: "Produce", quantity: "2 ct"),
            CartItem(name: "Chicken breast", category: "Protein", quantity: "1.5 lb"),
            CartItem(name: "Whole-grain bread", category: "Carbs", quantity: "1 loaf")
        ]
    }
}

private struct MealInsightTemplate {
    let source: MealLogSource
    let mealType: MealTypeValue
    let summary: String
    let rawInput: String
    let assetName: String?
    let suggestionImageName: String?
    let calories: Int
    let healthIndex: Int
    let healthLevel: String
    let healthTags: [String]
    let highlights: [String]
    let nutrition: NutritionBreakdown
    let suggestedSwap: String
    let cartItems: [CartItem]
}

//
//  NutritionAggregator.swift
//  Foodie
//
//

import Foundation

struct NutritionAggregator {
    private let targets: NutritionTargets

    init(targets: NutritionTargets) {
        self.targets = targets
    }

    func summarize(entries: [FoodLogEntry]) -> DailyNutritionSummary {
        var fiber: Double = 0
        var addedSugar: Double = 0
        var sodium: Double = 0
        var protein: Double = 0
        var carbs: Double = 0
        var fat: Double = 0
        var calorieEstimate: Double = 0
        var combinedConfidence = NutritionBreakdown.Confidence()
        var hasConfidenceData = false
        var notes: [String] = []
        var vegServings: Double = 0
        var fruitServings: Double = 0

        for entry in entries {
            if let nutrition = entry.nutrition {
                fiber += nutrition.totals.fiberGrams ?? 0
                addedSugar += nutrition.totals.addedSugarGrams ?? 0
                sodium += nutrition.totals.sodiumMilligrams ?? 0
                protein += nutrition.totals.proteinGrams ?? 0
                carbs += nutrition.totals.carbohydrateGrams ?? 0
                fat += nutrition.totals.fatGrams ?? 0
                calorieEstimate += nutrition.totals.calories ?? 0

                if let conf = nutrition.confidence {
                    if conf.overall != nil || conf.calories != nil || conf.protein != nil || conf.carbohydrates != nil || conf.fat != nil || conf.fiber != nil || conf.addedSugar != nil || conf.sodium != nil {
                        hasConfidenceData = true
                    }
                    combinedConfidence.overall = max(combinedConfidence.overall ?? 0, conf.overall ?? 0)
                    combinedConfidence.calories = max(combinedConfidence.calories ?? 0, conf.calories ?? 0)
                    combinedConfidence.protein = max(combinedConfidence.protein ?? 0, conf.protein ?? 0)
                    combinedConfidence.carbohydrates = max(combinedConfidence.carbohydrates ?? 0, conf.carbohydrates ?? 0)
                    combinedConfidence.fat = max(combinedConfidence.fat ?? 0, conf.fat ?? 0)
                    combinedConfidence.fiber = max(combinedConfidence.fiber ?? 0, conf.fiber ?? 0)
                    combinedConfidence.addedSugar = max(combinedConfidence.addedSugar ?? 0, conf.addedSugar ?? 0)
                    combinedConfidence.sodium = max(combinedConfidence.sodium ?? 0, conf.sodium ?? 0)
                }
                notes.append(contentsOf: nutrition.notes ?? [])

                vegServings += servings(from: nutrition.items, matching: ["vegetables", "leafy_greens"])
                fruitServings += servings(from: nutrition.items, matching: ["fruit"])
            } else if let calories = entry.estimatedCalories {
                calorieEstimate += Double(calories)
            }
        }

        let calorieTarget = targets.calorieGoal
        let calorieProgress = DailyNutritionSummary.MacroProgress(label: "Calories",
                                                                  consumed: calorieEstimate,
                                                                  target: calorieTarget,
                                                                  unit: "kcal")

        let proteinProgress = DailyNutritionSummary.MacroProgress(label: "Protein",
                                                                  consumed: protein,
                                                                  target: targets.proteinTargetGrams,
                                                                  unit: "g")
        let carbProgress = DailyNutritionSummary.MacroProgress(label: "Carbs",
                                                               consumed: carbs,
                                                               target: targets.carbohydrateTargetGrams,
                                                               unit: "g")
        let fatProgress = DailyNutritionSummary.MacroProgress(label: "Fat",
                                                              consumed: fat,
                                                              target: targets.fatTargetGrams,
                                                              unit: "g")

        let fiberStatus = DailyNutritionSummary.NutrientStatus(ratio: ratio(consumed: fiber, target: targets.fiberGoalGrams))
        let sugarStatus = DailyNutritionSummary.NutrientStatus(ratio: ratio(consumed: addedSugar, target: targets.addedSugarLimitGrams), upperBound: 1.0)
        let sodiumStatus = DailyNutritionSummary.NutrientStatus(ratio: ratio(consumed: sodium, target: targets.sodiumLimitMilligrams), upperBound: 1.0)

        let dietScore = DietQualityCalculator().score(proteinProgress: proteinProgress,
                                                      carbProgress: carbProgress,
                                                      fatProgress: fatProgress,
                                                      fiber: fiber,
                                                      fiberTarget: targets.fiberGoalGrams,
                                                      addedSugar: addedSugar,
                                                      addedSugarLimit: targets.addedSugarLimitGrams,
                                                      sodium: sodium,
                                                      sodiumLimit: targets.sodiumLimitMilligrams,
                                                      vegServings: vegServings,
                                                      vegTarget: targets.vegetableServingsTarget,
                                                      fruitServings: fruitServings,
                                                      fruitTarget: targets.fruitServingsTarget)

        let summary = DailyNutritionSummary(calorieMacro: calorieProgress,
                                            proteinMacro: proteinProgress,
                                            carbohydrateMacro: carbProgress,
                                            fatMacro: fatProgress,
                                            fiberStatus: (fiberStatus, fiber, targets.fiberGoalGrams),
                                            addedSugarStatus: (sugarStatus, addedSugar, targets.addedSugarLimitGrams),
                                            sodiumStatus: (sodiumStatus, sodium, targets.sodiumLimitMilligrams),
                                            vegetableServings: vegServings,
                                            fruitServings: fruitServings,
                                            vegetableTarget: targets.vegetableServingsTarget,
                                            fruitTarget: targets.fruitServingsTarget,
                                            confidence: hasConfidenceData ? combinedConfidence : nil,
                                            dietQuality: dietScore,
                                            notes: notes,
                                            highlights: highlightMessages(for: dietScore))
        return summary
    }

    private func ratio(consumed: Double, target: Double) -> Double {
        guard target > 0 else { return 0 }
        return consumed / target
    }

    private func servings(from items: [NutritionBreakdown.Item], matching tags: [String]) -> Double {
        items.reduce(0) { total, item in
            guard let itemTags = item.tags else { return total }
            guard itemTags.contains(where: tags.contains) else { return total }
            if let quantity = item.portion?.quantity {
                return total + max(quantity / 100, 0.25)
            }
            return total + 1
        }
    }

    private func highlightMessages(for score: DietQualityScore) -> [DailyNutritionSummary.Highlight] {
        score.components.sorted(by: { $0.score < $1.score }).prefix(2).map {
            DailyNutritionSummary.Highlight(title: $0.name, detail: $0.message)
        }
    }
}

private struct DietQualityCalculator {
    struct ComponentWeights {
        static let macros: Double = 0.4
        static let fiber: Double = 0.15
        static let sugar: Double = 0.15
        static let sodium: Double = 0.1
        static let produce: Double = 0.1
        static let wholeFood: Double = 0.1
    }

    func score(proteinProgress: DailyNutritionSummary.MacroProgress,
               carbProgress: DailyNutritionSummary.MacroProgress,
               fatProgress: DailyNutritionSummary.MacroProgress,
               fiber: Double,
               fiberTarget: Double,
               addedSugar: Double,
               addedSugarLimit: Double,
               sodium: Double,
               sodiumLimit: Double,
               vegServings: Double,
               vegTarget: Double,
               fruitServings: Double,
               fruitTarget: Double) -> DietQualityScore {

        let macroScore = averageScore([proteinProgress.progress, carbProgress.progress, fatProgress.progress])
        let fiberScore = cappedScore(consumed: fiber, target: fiberTarget)
        let sugarScore = inverseScore(consumed: addedSugar, limit: addedSugarLimit)
        let sodiumScore = inverseScore(consumed: sodium, limit: sodiumLimit)
        let produceScore = averageScore([
            min(vegServings / max(vegTarget, 1), 1.2),
            min(fruitServings / max(fruitTarget, 1), 1.2)
        ])

        let components: [DietQualityScore.Component] = [
            .init(name: "Macro Balance",
                  score: macroScore,
                  weight: ComponentWeights.macros,
                  message: message(for: macroScore, focus: "Balance your macros using protein, carbs, and healthy fats.")),
            .init(name: "Fiber",
                  score: fiberScore,
                  weight: ComponentWeights.fiber,
                  message: message(for: fiberScore, focus: "Add more fiber-rich foods like vegetables, beans, or whole grains.")),
            .init(name: "Added Sugar",
                  score: sugarScore,
                  weight: ComponentWeights.sugar,
                  message: message(for: sugarScore, focus: "Limit sweets and sugary drinks to stay within guidelines.")),
            .init(name: "Sodium",
                  score: sodiumScore,
                  weight: ComponentWeights.sodium,
                  message: message(for: sodiumScore, focus: "Reduce salty or processed foods to keep sodium in check.")),
            .init(name: "Produce",
                  score: produceScore,
                  weight: ComponentWeights.produce,
                  message: message(for: produceScore, focus: "Aim for at least five servings of fruits and vegetables."))
        ]

        let weightedTotal = components.reduce(0) { $0 + ($1.score * $1.weight) }
        let totalScore = Int(max(min(weightedTotal * 100, 100), 0).rounded())
        let grade = letterGrade(for: totalScore)
        let opportunity = components.min(by: { $0.score < $1.score })?.message ?? "Great job!"

        return DietQualityScore(total: totalScore,
                                grade: grade,
                                components: components,
                                topOpportunity: opportunity)
    }

    private func averageScore(_ values: [Double]) -> Double {
        let normalized = values.map { normalizedScore($0) }
        return normalized.reduce(0, +) / Double(normalized.count)
    }

    private func normalizedScore(_ ratio: Double) -> Double {
        if ratio == 0 { return 0 }
        if ratio < 0.8 { return ratio * 1.1 }
        if ratio > 1.2 { return max(0, 1.4 - ratio) }
        return 1
    }

    private func cappedScore(consumed: Double, target: Double) -> Double {
        guard target > 0 else { return 0 }
        let ratio = consumed / target
        if ratio >= 1 { return 1 }
        return max(0, ratio)
    }

    private func inverseScore(consumed: Double, limit: Double) -> Double {
        guard limit > 0 else { return 1 }
        let ratio = consumed / limit
        if ratio <= 1 { return 1 }
        return max(0, 1.2 - ratio)
    }

    private func letterGrade(for score: Int) -> String {
        switch score {
        case 90...: return "A"
        case 80..<90: return "B"
        case 70..<80: return "C"
        case 60..<70: return "D"
        default: return "E"
        }
    }

    private func message(for score: Double, focus: String) -> String {
        if score >= 0.9 { return "On track—keep it up!" }
        if score >= 0.7 { return "Almost there—focus on consistency." }
        return focus
    }
}



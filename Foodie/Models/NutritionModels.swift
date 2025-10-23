//
//  NutritionModels.swift
//  Foodie
//
//

import Foundation

struct NutritionTargets {
    struct MacroDistribution {
        var carbohydrates: Double // percentage of calories (0-1)
        var protein: Double
        var fat: Double

        static let `default` = MacroDistribution(carbohydrates: 0.50, protein: 0.25, fat: 0.25)
    }

    var calorieGoal: Double
    var macros: MacroDistribution
    var fiberGoalGrams: Double
    var addedSugarLimitGrams: Double
    var sodiumLimitMilligrams: Double
    var vegetableServingsTarget: Double
    var fruitServingsTarget: Double

    init(calorieGoal: Double,
         macros: MacroDistribution = .default,
         fiberGoalGrams: Double? = nil,
         addedSugarLimitGrams: Double? = nil,
         sodiumLimitMilligrams: Double = 2300,
         vegetableServingsTarget: Double = 2.5,
         fruitServingsTarget: Double = 2) {
        self.calorieGoal = calorieGoal
        self.macros = macros
        let fiberDefault = max(20, calorieGoal / 1000 * 14)
        let sugarDefault = (calorieGoal * 0.1) / 4
        self.fiberGoalGrams = fiberGoalGrams ?? fiberDefault
        self.addedSugarLimitGrams = addedSugarLimitGrams ?? sugarDefault
        self.sodiumLimitMilligrams = sodiumLimitMilligrams
        self.vegetableServingsTarget = vegetableServingsTarget
        self.fruitServingsTarget = fruitServingsTarget
    }

    var proteinTargetGrams: Double { (calorieGoal * macros.protein) / 4 }
    var carbohydrateTargetGrams: Double { (calorieGoal * macros.carbohydrates) / 4 }
    var fatTargetGrams: Double { (calorieGoal * macros.fat) / 9 }
}

struct DailyNutritionSummary {
    struct MacroProgress: Equatable {
        var label: String
        var consumed: Double
        var target: Double
        var unit: String

        var progress: Double {
            guard target > 0 else { return 0 }
            return consumed / target
        }
    }

    enum NutrientStatus: Equatable {
        case inadequate
        case onTrack
        case excessive

        init(ratio: Double, lowerBound: Double = 0.9, upperBound: Double = 1.1) {
            if ratio < lowerBound { self = .inadequate }
            else if ratio > upperBound { self = .excessive }
            else { self = .onTrack }
        }
    }

    struct Highlight: Equatable {
        var title: String
        var detail: String
    }

    var calorieMacro: MacroProgress
    var proteinMacro: MacroProgress
    var carbohydrateMacro: MacroProgress
    var fatMacro: MacroProgress
    var fiberStatus: (status: NutrientStatus, consumed: Double, target: Double)
    var addedSugarStatus: (status: NutrientStatus, consumed: Double, limit: Double)
    var sodiumStatus: (status: NutrientStatus, consumed: Double, limit: Double)
    var vegetableServings: Double
    var fruitServings: Double
    var vegetableTarget: Double
    var fruitTarget: Double
    var confidence: NutritionBreakdown.Confidence?
    var dietQuality: DietQualityScore
    var notes: [String]
    var highlights: [Highlight]
}

struct DietQualityScore: Equatable {
    struct Component: Equatable {
        var name: String
        var score: Double
        var weight: Double
        var message: String
    }

    var total: Int
    var grade: String
    var components: [Component]
    var topOpportunity: String
}



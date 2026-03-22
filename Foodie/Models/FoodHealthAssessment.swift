//
//  FoodHealthAssessment.swift
//  Foodie
//
//

import Foundation

struct FoodHealthAssessment: Codable, Hashable {
    let score: Int
    let level: String
    let axes: Axes
    let tags: [String]
    let highlights: [String]

    struct Axes: Codable, Hashable {
        let nutrientDensity: Int
        let processing: Int
        let sugarLoad: Int
        let saturatedFat: Int
        let sodium: Int
        let positives: Int
    }
}


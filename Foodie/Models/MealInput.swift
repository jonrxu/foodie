//
//  MealInput.swift
//  Foodie
//

import Foundation

enum MealInput {
    case text(String)
    case voice(String)
    case photo(Data, String)   // data, mimeType
    case barcode(String)

    var source: MealLogSource {
        switch self {
        case .text:    return .text
        case .voice:   return .voice
        case .photo:   return .photo
        case .barcode: return .barcode
        }
    }

    var rawText: String {
        switch self {
        case .text(let s), .voice(let s), .barcode(let s): return s
        case .photo: return ""
        }
    }
}

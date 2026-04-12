//
//  CartDraft.swift
//  Foodie
//

import Foundation

enum CartDraftSource: String, Codable, CaseIterable, Hashable {
    case groceryPlanner
    case mealFeedback
    case weeklyCart
    case manual
    case imported
}

struct CartItem: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var category: String?
    var quantity: String?
    var notes: String?
    var estimatedPrice: Double?
    var isSelected: Bool

    init(id: UUID = UUID(),
         name: String,
         category: String? = nil,
         quantity: String? = nil,
         notes: String? = nil,
         estimatedPrice: Double? = nil,
         isSelected: Bool = true) {
        self.id = id
        self.name = name
        self.category = category
        self.quantity = quantity
        self.notes = notes
        self.estimatedPrice = estimatedPrice
        self.isSelected = isSelected
    }
}

struct CartDraft: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var source: CartDraftSource
    var storeName: String?
    var createdAt: Date
    var updatedAt: Date
    var totalEstimate: Double?
    var checkoutURL: URL?
    var items: [CartItem]

    init(id: UUID = UUID(),
         title: String,
         source: CartDraftSource,
         storeName: String? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date(),
         totalEstimate: Double? = nil,
         checkoutURL: URL? = nil,
         items: [CartItem] = []) {
        self.id = id
        self.title = title
        self.source = source
        self.storeName = storeName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.totalEstimate = totalEstimate
        self.checkoutURL = checkoutURL
        self.items = items
    }
}


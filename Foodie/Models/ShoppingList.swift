//
//  ShoppingList.swift
//  Foodie
//
//

import Foundation
import CoreLocation

struct ShoppingList: Identifiable, Codable, Hashable {
    enum Source: String, Codable { case instacart, manual }
    enum Status: String, Codable { case pending, completed, archived }

    struct Item: Identifiable, Codable, Hashable {
        let id: UUID
        var name: String
        var quantity: String?
        var note: String?
        var estimatedPrice: Double?
        var storeName: String?

        init(id: UUID = UUID(), name: String, quantity: String? = nil, note: String? = nil, estimatedPrice: Double? = nil, storeName: String? = nil) {
            self.id = id
            self.name = name
            self.quantity = quantity
            self.note = note
            self.estimatedPrice = estimatedPrice
            self.storeName = storeName
        }
    }

    let id: UUID
    var title: String
    var storeName: String
    var totalEstimate: Double?
    var itemCount: Int
    var createdAt: Date
    var updatedAt: Date
    var link: URL?
    var source: Source
    var status: Status
    var items: [Item]
    var locationCoordinate: Coordinate?

    struct Coordinate: Codable, Hashable {
        let latitude: Double
        let longitude: Double

        init(_ coordinate: CLLocationCoordinate2D) {
            latitude = coordinate.latitude
            longitude = coordinate.longitude
        }

        var clLocationCoordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }

    init(id: UUID = UUID(),
         title: String,
         storeName: String,
         totalEstimate: Double? = nil,
         itemCount: Int,
         createdAt: Date = Date(),
         updatedAt: Date = Date(),
         link: URL? = nil,
         source: Source,
         status: Status = .pending,
         items: [Item],
         locationCoordinate: CLLocationCoordinate2D? = nil) {
        self.id = id
        self.title = title
        self.storeName = storeName
        self.totalEstimate = totalEstimate
        self.itemCount = itemCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.link = link
        self.source = source
        self.status = status
        self.items = items
        if let coordinate = locationCoordinate {
            self.locationCoordinate = Coordinate(coordinate)
        } else {
            self.locationCoordinate = nil
        }
    }
}

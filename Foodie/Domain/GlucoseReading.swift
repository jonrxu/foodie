//
//  GlucoseReading.swift
//  Foodie
//

import Foundation

enum GlucoseSource: String, Codable, CaseIterable, Hashable {
    case dexcom
    case manual
    case simulated
}

enum GlucoseTrend: String, Codable, CaseIterable, Hashable {
    case doubleUp
    case singleUp
    case flat
    case singleDown
    case doubleDown
    case unknown
}

struct GlucoseReading: Identifiable, Codable, Hashable {
    let id: UUID
    var timestamp: Date
    var valueMgdl: Int
    var source: GlucoseSource
    var trend: GlucoseTrend?

    init(id: UUID = UUID(),
         timestamp: Date,
         valueMgdl: Int,
         source: GlucoseSource,
         trend: GlucoseTrend? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.valueMgdl = valueMgdl
        self.source = source
        self.trend = trend
    }
}

struct GlucoseSummary: Codable, Hashable {
    var startDate: Date
    var endDate: Date
    var targetLowMgdl: Int
    var targetHighMgdl: Int
    var averageMgdl: Double?
    var timeInRangePercent: Int?
    var readings: [GlucoseReading]

    init(startDate: Date,
         endDate: Date,
         targetLowMgdl: Int = 70,
         targetHighMgdl: Int = 180,
         averageMgdl: Double? = nil,
         timeInRangePercent: Int? = nil,
         readings: [GlucoseReading] = []) {
        self.startDate = startDate
        self.endDate = endDate
        self.targetLowMgdl = targetLowMgdl
        self.targetHighMgdl = targetHighMgdl
        self.averageMgdl = averageMgdl
        self.timeInRangePercent = timeInRangePercent
        self.readings = readings
    }
}

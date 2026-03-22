//
//  SpikeEvent.swift
//  Foodie
//

import Foundation

enum SpikeEventKind: String, Codable, CaseIterable, Hashable {
    case measured
    case predicted
}

enum SpikeEventStatus: String, Codable, CaseIterable, Hashable {
    case open
    case resolved
    case dismissed
}

struct SpikeMetrics: Codable, Hashable {
    var baselineMgdl: Double
    var peakMgdl: Double
    var deltaMgdl: Double
    var timeToPeakMinutes: Int?
    var returnToRangeMinutes: Int?

    init(baselineMgdl: Double,
         peakMgdl: Double,
         deltaMgdl: Double,
         timeToPeakMinutes: Int? = nil,
         returnToRangeMinutes: Int? = nil) {
        self.baselineMgdl = baselineMgdl
        self.peakMgdl = peakMgdl
        self.deltaMgdl = deltaMgdl
        self.timeToPeakMinutes = timeToPeakMinutes
        self.returnToRangeMinutes = returnToRangeMinutes
    }
}

struct SpikeEvent: Identifiable, Codable, Hashable {
    let id: UUID
    var mealLogID: UUID
    var createdAt: Date
    var eventKind: SpikeEventKind
    var status: SpikeEventStatus
    var startedAt: Date
    var peakAt: Date?
    var resolvedAt: Date?
    var confidence: Double
    var metrics: SpikeMetrics
    var notes: [String]

    init(id: UUID = UUID(),
         mealLogID: UUID,
         createdAt: Date = Date(),
         eventKind: SpikeEventKind,
         status: SpikeEventStatus = .open,
         startedAt: Date,
         peakAt: Date? = nil,
         resolvedAt: Date? = nil,
         confidence: Double,
         metrics: SpikeMetrics,
         notes: [String] = []) {
        self.id = id
        self.mealLogID = mealLogID
        self.createdAt = createdAt
        self.eventKind = eventKind
        self.status = status
        self.startedAt = startedAt
        self.peakAt = peakAt
        self.resolvedAt = resolvedAt
        self.confidence = confidence
        self.metrics = metrics
        self.notes = notes
    }
}

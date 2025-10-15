//
//  DateCodingStrategy.swift
//  Foodie
//
//  Created by AI Assistant.
//

import Foundation

extension JSONDecoder.DateDecodingStrategy {
    static var iso8601WithFallback: JSONDecoder.DateDecodingStrategy {
        .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = ISO8601DateFormatter().date(from: string) {
                return date
            }

            let formatter1 = DateFormatter()
            formatter1.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            if let date = formatter1.date(from: string) {
                return date
            }

            let formatter2 = DateFormatter()
            formatter2.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
            if let date = formatter2.date(from: string) {
                return date
            }

            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "Invalid date format: \(string)")
        }
    }
}

extension JSONEncoder.DateEncodingStrategy {
    static var iso8601WithFallback: JSONEncoder.DateEncodingStrategy {
        .custom { date, encoder in
            var container = encoder.singleValueContainer()
            let formatter = ISO8601DateFormatter()
            let string = formatter.string(from: date)
            try container.encode(string)
        }
    }
}



//
//  JSONFileStorage.swift
//  Foodie
//

import Foundation

final class JSONFileStorage {
    private let fileName: String

    init(fileName: String) {
        self.fileName = fileName
    }

    private var fileURL: URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return directory.appendingPathComponent(fileName)
    }

    func load<T: Decodable>(_ type: T.Type) -> T? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601WithFallback
        return try? decoder.decode(type, from: data)
    }

    func save<T: Encodable>(_ value: T) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601WithFallback
        guard let data = try? encoder.encode(value) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}

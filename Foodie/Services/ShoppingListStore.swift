//
//  ShoppingListStore.swift
//  Foodie
//
//

import Foundation

final class ShoppingListStore: ObservableObject {
    static let shared = ShoppingListStore()

    @Published private(set) var shoppingLists: [ShoppingList] = []

    private let fileName = "shopping_lists.json"
    private let queue = DispatchQueue(label: "shopping-list-store", qos: .background)
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private init() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        load()
    }

    private var storageURL: URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return directory.appendingPathComponent(fileName)
    }

    func load() {
        let url = storageURL
        guard let data = try? Data(contentsOf: url) else { return }
        if let decoded = try? decoder.decode([ShoppingList].self, from: data) {
            shoppingLists = decoded.sorted(by: { $0.updatedAt > $1.updatedAt })
        }
    }

    func save() {
        let lists = shoppingLists
        queue.async { [encoder, storageURL] in
            guard let data = try? encoder.encode(lists) else { return }
            try? data.write(to: storageURL, options: [.atomic])
        }
    }

    func add(_ list: ShoppingList) {
        shoppingLists.insert(list, at: 0)
        save()
    }

    func update(_ list: ShoppingList) {
        if let index = shoppingLists.firstIndex(where: { $0.id == list.id }) {
            shoppingLists[index] = list
            shoppingLists.sort(by: { $0.updatedAt > $1.updatedAt })
            save()
        }
    }

    func delete(_ list: ShoppingList) {
        shoppingLists.removeAll { $0.id == list.id }
        save()
    }

    func markCompleted(_ list: ShoppingList) {
        guard let index = shoppingLists.firstIndex(where: { $0.id == list.id }) else { return }
        shoppingLists[index].status = .completed
        shoppingLists[index].updatedAt = Date()
        shoppingLists.sort(by: { $0.updatedAt > $1.updatedAt })
        save()
    }
}

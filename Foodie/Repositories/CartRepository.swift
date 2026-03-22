//
//  CartRepository.swift
//  Foodie
//

import Foundation

protocol CartRepository {
    func fetchAllDrafts() async throws -> [CartDraft]
    func saveDraft(_ draft: CartDraft) async throws
    func deleteDraft(id: UUID) async throws
}

extension CartRepository {
    func fetchLatestDraft() async throws -> CartDraft? {
        try await fetchAllDrafts().sorted(by: { $0.updatedAt > $1.updatedAt }).first
    }
}

final class LocalCartRepository: CartRepository {
    private let storage = JSONFileStorage(fileName: "cart_drafts.json")
    private let legacyStore: ShoppingListStore

    init(legacyStore: ShoppingListStore = .shared) {
        self.legacyStore = legacyStore
    }

    func fetchAllDrafts() async throws -> [CartDraft] {
        let savedDrafts = storage.load([CartDraft].self) ?? []
        let legacyDrafts = legacyStore.shoppingLists.map(CartDraft.init(legacy:))

        var merged: [UUID: CartDraft] = [:]
        for draft in legacyDrafts {
            merged[draft.id] = draft
        }
        for draft in savedDrafts {
            merged[draft.id] = draft
        }

        return merged.values.sorted(by: { $0.updatedAt > $1.updatedAt })
    }

    func saveDraft(_ draft: CartDraft) async throws {
        var drafts = try await fetchAllDrafts()
        if let index = drafts.firstIndex(where: { $0.id == draft.id }) {
            drafts[index] = draft
        } else {
            drafts.append(draft)
        }
        storage.save(drafts.sorted(by: { $0.updatedAt > $1.updatedAt }))
        let legacyList = ShoppingList(domain: draft)
        if legacyStore.shoppingLists.contains(where: { $0.id == draft.id }) {
            legacyStore.update(legacyList)
        } else {
            legacyStore.add(legacyList)
        }
    }

    func deleteDraft(id: UUID) async throws {
        let drafts = try await fetchAllDrafts().filter { $0.id != id }
        storage.save(drafts)
        if let existing = legacyStore.shoppingLists.first(where: { $0.id == id }) {
            legacyStore.delete(existing)
        }
    }
}

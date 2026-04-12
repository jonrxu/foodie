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

    func fetchAllDrafts() async throws -> [CartDraft] {
        return storage.load([CartDraft].self) ?? []
    }

    func saveDraft(_ draft: CartDraft) async throws {
        var drafts = try await fetchAllDrafts()
        if let index = drafts.firstIndex(where: { $0.id == draft.id }) {
            drafts[index] = draft
        } else {
            drafts.append(draft)
        }
        storage.save(drafts.sorted(by: { $0.updatedAt > $1.updatedAt }))
    }

    func deleteDraft(id: UUID) async throws {
        let drafts = try await fetchAllDrafts().filter { $0.id != id }
        storage.save(drafts)
    }
}

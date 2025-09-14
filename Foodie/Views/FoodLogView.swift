//
//  FoodLogView.swift
//  Foodie
//
//  Created by AI Assistant.
//

import SwiftUI

struct FoodLogView: View {
    @State private var showingCamera = false
    @State private var showingLibrary = false
    @State private var isAnalyzing = false
    @State private var draftSummary: String = ""
    @State private var pendingImage: UIImage?
    @State private var logs: [FoodLogEntry] = FoodLogStore.shared.load().sorted(by: { $0.date > $1.date })

    var body: some View {
        VStack(spacing: 16) {
            header
            captureRow
            gallery
            Spacer()
        }
        .padding()
        .background(AppTheme.background)
        .sheet(isPresented: $showingCamera) {
            ImagePicker(source: .camera) { image in
                pendingImage = image
                Task { await analyzePendingImage() }
            }
        }
        .sheet(isPresented: $showingLibrary) {
            ImagePicker(source: .library) { image in
                pendingImage = image
                Task { await analyzePendingImage() }
            }
        }
        .alert("Save this entry?", isPresented: Binding(get: { !draftSummary.isEmpty && !isAnalyzing }, set: { _ in })) {
            Button("Edit") { }
            Button("Save") { saveDraft() }
            Button("Discard", role: .destructive) { draftSummary = ""; pendingImage = nil }
        } message: {
            Text(draftSummary)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Food Log")
                .font(.title2).bold()
            Text("Snap meals, I’ll estimate nutrition")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var captureRow: some View {
        HStack(spacing: 12) {
            Button {
                showingCamera = true
            } label: {
                Label("Capture", systemImage: "camera.fill")
                    .font(.headline)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(AppTheme.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            Button {
                showingLibrary = true
            } label: {
                Label("Import", systemImage: "photo.fill.on.rectangle.fill")
                    .font(.headline)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(AppTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            if isAnalyzing {
                ProgressView().progressViewStyle(.circular)
            }
            Spacer()
        }
    }

    private var gallery: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent")
                .font(.headline)
            if logs.isEmpty {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppTheme.card)
                    .frame(height: 160)
                    .overlay {
                        VStack(spacing: 6) {
                            Image(systemName: "text.justify")
                                .font(.system(size: 28))
                                .foregroundStyle(.secondary)
                            Text("Your saved summaries will appear here")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
            } else {
                ForEach(logs) { entry in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Image(systemName: "fork.knife")
                            .foregroundStyle(AppTheme.primary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.summary)
                                .font(.body)
                            Text(entry.date, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(AppTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }

    private func analyzePendingImage() async {
        guard let uiImage = pendingImage, let data = uiImage.jpegData(compressionQuality: 0.8) else { return }
        isAnalyzing = true
        defer { isAnalyzing = false }
        do {
            let result = try await OpenAIClient().analyzeFoodImage(imageData: data)
            await MainActor.run {
                draftSummary = result.summary
            }
        } catch {
            await MainActor.run { draftSummary = "Couldn’t analyze the photo. Please try again." }
        }
        pendingImage = nil // always discard image
    }

    private func saveDraft() {
        guard !draftSummary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { draftSummary = ""; return }
        var current = FoodLogStore.shared.load()
        current.insert(FoodLogEntry(summary: draftSummary), at: 0)
        FoodLogStore.shared.save(current)
        logs = current
        draftSummary = ""
    }
}

#Preview {
    NavigationStack { FoodLogView() }
}



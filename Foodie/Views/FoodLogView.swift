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
    @State private var activeAnalyses = 0
    @State private var errorMessage: String?
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
                Task { await analyzeImage(image) }
            }
        }
        .sheet(isPresented: $showingLibrary) {
            ImagePicker(source: .library) { image in
                Task { await analyzeImage(image) }
            }
        }
        .alert("Analysis Failed", isPresented: Binding(get: { errorMessage != nil }, set: { newValue in
            if !newValue { errorMessage = nil }
        })) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
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
            if activeAnalyses > 0 {
                ProgressView().progressViewStyle(.circular)
            }
            Spacer()
        }
    }

    private var gallery: some View {
        VStack(alignment: .leading, spacing: 10) {
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
                ForEach(groupedLogs, id: \.date) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(dayLabel(for: group.date))
                            .font(.headline)
                        ForEach(group.entries) { entry in
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Image(systemName: "fork.knife")
                                    .foregroundStyle(AppTheme.primary)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.summary)
                                        .font(.body)
                                    Text(entry.date, style: .time)
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
        }
    }

    private func analyzeImage(_ image: UIImage) async {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        await MainActor.run { activeAnalyses += 1 }
        do {
            let result = try await OpenAIClient().analyzeFoodImage(imageData: data)
            await MainActor.run {
                let newEntry = FoodLogEntry(summary: result.summary,
                                             confidence: result.confidence,
                                             mealType: result.mealType)
                logs.insert(newEntry, at: 0)
                logs.sort(by: { $0.date > $1.date })
                FoodLogStore.shared.save(logs)
            }
        } catch {
            await MainActor.run {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? "Couldn’t analyze the photo. Please try again."
            }
        }
        await MainActor.run {
            activeAnalyses = max(activeAnalyses - 1, 0)
        }
    }

    private var groupedLogs: [(date: Date, entries: [FoodLogEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: logs) { calendar.startOfDay(for: $0.date) }
        return grouped
            .map { (date: $0.key, entries: $0.value.sorted(by: { $0.date > $1.date })) }
            .sorted(by: { $0.date > $1.date })
    }

    private func dayLabel(for date: Date) -> String {
        Self.dayFormatter.string(from: date)
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()
}

#Preview {
    NavigationStack { FoodLogView() }
}

//
//  FoodLogView.swift
//  Foodie
//
//  Created by AI Assistant.
//

import SwiftUI

struct FoodLogView: View {
    @State private var showingCamera = false
//    @State private var showingLibrary = false // Re-enable if photo library import returns
    @State private var showingManualEntry = false
    @State private var manualEntryText = ""
    @State private var activeAnalyses = 0
    @State private var alertTitle: String = ""
    @State private var alertMessage: String?
    @State private var logs: [FoodLogEntry] = FoodLogStore.shared.load().sorted(by: { $0.date > $1.date })

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20, pinnedViews: []) {
                header

                captureRow

                if logs.isEmpty {
                    emptyStateView
                } else {
                    ForEach(groupedLogs, id: \.date) { group in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(dayLabel(for: group.date))
                                .font(.headline)
                            ForEach(group.entries) { entry in
                                entryRow(for: entry)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical, 20)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .fullScreenCover(isPresented: $showingCamera) {
            ZStack {
                Color.black.ignoresSafeArea()
                ImagePicker(source: .camera) { image in
                    Task { await analyzeImage(image) }
                }
                .ignoresSafeArea()
            }
        }
//        .sheet(isPresented: $showingLibrary) {
//            ImagePicker(source: .library) { image in
//                Task { await analyzeImage(image) }
//            }
//        }
        .sheet(isPresented: $showingManualEntry) {
            manualEntrySheet
        }
        .alert(alertTitle.isEmpty ? "Notice" : alertTitle,
               isPresented: Binding(get: { alertMessage != nil }, set: { newValue in
                   if !newValue {
                       alertTitle = ""
                       alertMessage = nil
                   }
               })) {
            Button("OK", role: .cancel) {
                alertTitle = ""
                alertMessage = nil
            }
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Food Log")
                .font(.title2).bold()
            Text("Snap meals, I’ll estimate nutrition")
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
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
            .buttonStyle(.plain)

            Button {
                manualEntryText = ""
                showingManualEntry = true
            } label: {
                Label("Quick Log", systemImage: "square.and.pencil")
                    .font(.headline)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(AppTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            if activeAnalyses > 0 {
                ProgressView().progressViewStyle(.circular)
            }
        }
        .padding(.horizontal)
    }

    private var emptyStateView: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(AppTheme.card)
            .frame(height: 180)
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
            .padding(.horizontal)
    }

    private func analyzeImage(_ image: UIImage) async {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        await MainActor.run { activeAnalyses += 1 }
        do {
            let result = try await OpenAIClient().analyzeFoodImage(imageData: data)
            if result.detected == false || result.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                await MainActor.run {
                    alertTitle = "No Meal Detected"
                    alertMessage = "We couldn’t find any food in that photo. Try again or use Quick Log."
                }
            } else {
                try await persistEntry(summary: result.summary,
                                      estimatedCalories: result.estimatedCalories,
                                      confidence: result.confidence,
                                      mealType: result.mealType)
            }
        } catch {
            await MainActor.run {
                alertTitle = "Analysis Failed"
                alertMessage = (error as? LocalizedError)?.errorDescription ?? "Couldn’t analyze the photo. Please try again."
            }
        }
        await MainActor.run {
            activeAnalyses = max(activeAnalyses - 1, 0)
        }
    }

    private func handleManualEntry(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        await MainActor.run { activeAnalyses += 1 }
        do {
            try await persistEntry(summary: trimmed, estimatedCalories: nil, confidence: nil, mealType: nil)
        } catch {
            await MainActor.run {
                alertTitle = "Logging Failed"
                alertMessage = (error as? LocalizedError)?.errorDescription ?? "Couldn’t analyze that entry. Please try again."
            }
        }
        await MainActor.run {
            activeAnalyses = max(activeAnalyses - 1, 0)
        }
    }

    private func persistEntry(summary: String,
                              estimatedCalories: Int?,
                              confidence: Double?,
                              mealType: String?) async throws {
        let assessment = try await FoodHealthIndexer.shared.assess(summary: summary)
        let newEntry = FoodLogEntry(summary: summary,
                                    estimatedCalories: estimatedCalories,
                                    confidence: confidence,
                                    mealType: mealType,
                                    healthIndex: assessment.score,
                                    healthTags: assessment.tags,
                                    healthHighlights: assessment.highlights)
        await MainActor.run {
            logs.insert(newEntry, at: 0)
            logs.sort(by: { $0.date > $1.date })
            FoodLogStore.shared.save(logs)
        }
    }

    private func deleteEntry(_ entry: FoodLogEntry) {
        if let index = logs.firstIndex(of: entry) {
            logs.remove(at: index)
            FoodLogStore.shared.save(logs)
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

    private var manualEntrySheet: some View {
        NavigationStack {
            Form {
                Section("Describe what you ate") {
                    TextEditor(text: $manualEntryText)
                        .frame(minHeight: 160)
                }
            }
            .navigationTitle("Quick Log")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingManualEntry = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let text = manualEntryText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !text.isEmpty else { return }
                        showingManualEntry = false
                        manualEntryText = ""
                        Task { await handleManualEntry(text) }
                    }
                    .disabled(manualEntryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func metaRow(for entry: FoodLogEntry) -> some View {
        HStack(spacing: 8) {
            Text(entry.date, style: .time)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let calories = entry.estimatedCalories {
                Divider().frame(height: 12)
                Text("\(calories) kcal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func tagsRow(for entry: FoodLogEntry) -> some View {
        HStack {
            ForEach(entry.healthTags ?? [], id: \.self) { tag in
                Text(label(for: tag))
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(tagBackground(for: tag))
                    .foregroundStyle(tagForeground(for: tag))
                    .clipShape(Capsule())
            }
        }
    }

    private func label(for tag: String) -> String {
        switch tag {
        case "whole_foods": return "Whole food"
        case "vegetables": return "Veg"
        case "lean_protein": return "Lean protein"
        case "whole_grain": return "Whole grain"
        case "fruit": return "Fruit"
        case "ultra_processed": return "Ultra-processed"
        case "added_sugar": return "Added sugar"
        case "fried": return "Fried"
        case "high_sodium": return "High sodium"
        case "saturated_fat": return "Sat fat"
        default: return tag.replacingOccurrences(of: "_", with: " ")
        }
    }

    private func tagBackground(for tag: String) -> Color {
        switch tag {
        case "whole_foods", "vegetables", "lean_protein", "whole_grain", "fruit":
            return Color.green.opacity(0.2)
        default:
            return Color.red.opacity(0.15)
        }
    }

    private func tagForeground(for tag: String) -> Color {
        switch tag {
        case "whole_foods", "vegetables", "lean_protein", "whole_grain", "fruit":
            return Color.green
        default:
            return Color.red
        }
    }

    private func entryRow(for entry: FoodLogEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            HealthScoreBadge(score: entry.healthIndex)
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.summary)
                    .font(.body)
                metaRow(for: entry)
                if let highlight = entry.healthHighlights?.first {
                    Text(highlight)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                tagsRow(for: entry)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                deleteEntry(entry)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    NavigationStack { FoodLogView() }
}

//
//  FoodLogView.swift
//  Foodie
//
//

import SwiftUI

struct FoodLogView: View {
    @State private var showingCamera = false
//    @State private var showingLibrary = false // Re-enable if photo library import returns
    @State private var showingManualEntry = false
    @State private var manualEntryText = ""
    @State private var manualEntryCalories = ""
    @State private var activeAnalyses = 0
    @State private var alertTitle: String = ""
    @State private var alertMessage: String?
    @State private var logs: [FoodLogEntry] = FoodLogStore.shared.load().sorted(by: { $0.date > $1.date })
    @State private var showingClearConfirmation = false
    @EnvironmentObject private var preferences: UserPreferences

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                captureRow

                DailySummaryCard(entries: todaysEntries, calorieGoal: preferences.dailyCalorieGoal)

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
                    
                    // Clear All button at bottom
                    Button(role: .destructive) {
                        showingClearConfirmation = true
                    } label: {
                        Label("Clear All Logs", systemImage: "trash")
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.red.opacity(0.1))
                            .foregroundStyle(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
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
        .alert("Clear All Food Logs?",
               isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                clearAllLogs()
            }
        } message: {
            Text("This will permanently delete all food log entries and reset your daily nutrition summary.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Food Log")
                .font(.title2).bold()
            Text("Snap meals, I'll estimate nutrition")
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
                manualEntryCalories = ""
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
        print("🖼️ [FoodLogView] analyzeImage() called")
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            print("❌ [FoodLogView] Failed to convert image to JPEG data")
            return
        }
        print("📷 [FoodLogView] Image data size: \(data.count) bytes")
        await MainActor.run { activeAnalyses += 1 }
        do {
            print("🚀 [FoodLogView] Calling OpenAI analyzeFoodImage...")
            let result = try await OpenAIClient().analyzeFoodImage(imageData: data)
            print("✅ [FoodLogView] Got result from OpenAI: detected=\(result.detected)")
            if result.detected == false || result.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                await MainActor.run {
                    alertTitle = "No Meal Detected"
                    alertMessage = "We couldn't find any food in that photo. Try again or use Quick Log."
                }
            } else {
                let nutritionData = extractNutritionBreakdown(from: result)
                try await persistEntry(summary: result.summary,
                                      estimatedCalories: result.estimatedCalories,
                                      confidence: result.confidence,
                                      mealType: result.mealType,
                                      nutrition: nutritionData)
            }
        } catch {
            print("❌ [FoodLogView] Error analyzing image: \(error)")
            await MainActor.run {
                alertTitle = "Analysis Failed"
                alertMessage = (error as? LocalizedError)?.errorDescription ?? "Couldn't analyze the photo. Please try again."
            }
        }
        await MainActor.run {
            activeAnalyses = max(activeAnalyses - 1, 0)
        }
    }

    private func handleManualEntry(_ text: String, caloriesInput: String) async {
        print("📝 [FoodLogView] handleManualEntry() called with text: '\(text)'")
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            print("⚠️ [FoodLogView] Empty text, returning")
            return
        }

        var providedCalories: Int?
        if !caloriesInput.isEmpty {
            if let parsed = Int(caloriesInput) {
                providedCalories = parsed
                print("💯 [FoodLogView] User provided calories: \(parsed)")
            } else {
                await MainActor.run {
                    alertTitle = "Invalid Calories"
                    alertMessage = "Please enter calories using digits only."
                }
                print("❌ [FoodLogView] Invalid calories input: '\(caloriesInput)'")
                return
            }
        }

        await MainActor.run { activeAnalyses += 1 }

        var summaryForLog = trimmed
        var caloriesForLog = providedCalories
        var confidenceForLog: Double?
        var mealTypeForLog: String?
        var nutritionForLog: NutritionBreakdown?

        if providedCalories == nil {
            print("🚀 [FoodLogView] No calories provided, calling OpenAI estimateCalories...")
            do {
                let result = try await OpenAIClient().estimateCalories(for: trimmed)
                print("✅ [FoodLogView] Got result from OpenAI: detected=\(result.detected)")
                if result.detected {
                    caloriesForLog = result.estimatedCalories
                    confidenceForLog = result.confidence
                    mealTypeForLog = result.mealType
                    nutritionForLog = extractNutritionBreakdown(from: result)
                }
            } catch {
                print("❌ [FoodLogView] Error estimating calories: \(error)")
                await MainActor.run {
                    alertTitle = "Estimation Failed"
                    alertMessage = (error as? LocalizedError)?.errorDescription ?? "Couldn't estimate calories for that entry. We'll save it without calories."
                }
            }
        }

        do {
            print("💾 [FoodLogView] Persisting entry...")
            try await persistEntry(summary: summaryForLog,
                                   estimatedCalories: caloriesForLog,
                                   confidence: confidenceForLog,
                                   mealType: mealTypeForLog,
                                   nutrition: nutritionForLog)
            print("✅ [FoodLogView] Entry persisted successfully")
        } catch {
            print("❌ [FoodLogView] Error persisting entry: \(error)")
            await MainActor.run {
                alertTitle = "Logging Failed"
                alertMessage = (error as? LocalizedError)?.errorDescription ?? "Couldn't analyze that entry. Please try again."
            }
        }

        await MainActor.run {
            activeAnalyses = max(activeAnalyses - 1, 0)
        }
    }

    private func extractNutritionBreakdown(from result: OpenAIClient.FoodAnalysisResult) -> NutritionBreakdown? {
        guard let totals = result.nutritionTotals else { return nil }
        
        let nutritionTotals = NutritionBreakdown.Totals(
            calories: totals.calories,
            proteinGrams: totals.proteinGrams,
            carbohydrateGrams: totals.carbohydrateGrams,
            fatGrams: totals.fatGrams,
            fiberGrams: totals.fiberGrams,
            addedSugarGrams: totals.addedSugarGrams,
            sodiumMilligrams: totals.sodiumMilligrams,
            saturatedFatGrams: totals.saturatedFatGrams,
            unsaturatedFatGrams: totals.unsaturatedFatGrams
        )
        
        let nutritionItems = result.nutritionItems?.map { item in
            NutritionBreakdown.Item(
                name: item.name,
                description: item.description,
                portion: item.portion.map {
                    NutritionBreakdown.Portion(unit: $0.unit, quantity: $0.quantity, text: $0.text)
                },
                totals: NutritionBreakdown.Totals(
                    calories: item.totals.calories,
                    proteinGrams: item.totals.proteinGrams,
                    carbohydrateGrams: item.totals.carbohydrateGrams,
                    fatGrams: item.totals.fatGrams,
                    fiberGrams: item.totals.fiberGrams,
                    addedSugarGrams: item.totals.addedSugarGrams,
                    sodiumMilligrams: item.totals.sodiumMilligrams,
                    saturatedFatGrams: item.totals.saturatedFatGrams,
                    unsaturatedFatGrams: item.totals.unsaturatedFatGrams
                ),
                confidence: item.confidence,
                tags: item.tags
            )
        } ?? []
        
        let nutritionConfidence = result.nutritionConfidence.map {
            NutritionBreakdown.Confidence(
                overall: $0.overall,
                calories: $0.calories,
                protein: $0.protein,
                carbohydrates: $0.carbohydrates,
                fat: $0.fat,
                fiber: $0.fiber,
                addedSugar: $0.addedSugar,
                sodium: $0.sodium
            )
        }
        
        return NutritionBreakdown(
            totals: nutritionTotals,
            items: nutritionItems,
            confidence: nutritionConfidence,
            notes: result.notes
        )
    }

    private func persistEntry(summary: String,
                              estimatedCalories: Int?,
                              confidence: Double?,
                              mealType: String?,
                              nutrition: NutritionBreakdown? = nil) async throws {
        let assessment = try await FoodHealthIndexer.shared.assess(summary: summary)
        let newEntry = FoodLogEntry(summary: summary,
                                    estimatedCalories: estimatedCalories,
                                    confidence: confidence,
                                    mealType: mealType,
                                    healthIndex: assessment.score,
                                    healthTags: assessment.tags,
                                    healthHighlights: assessment.highlights,
                                    nutrition: nutrition)
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
    
    private func clearAllLogs() {
        print("🗑️ [FoodLogView] Clearing all food logs")
        logs.removeAll()
        FoodLogStore.shared.save(logs)
        print("✅ [FoodLogView] All logs cleared successfully")
    }

    private var groupedLogs: [(date: Date, entries: [FoodLogEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: logs) { calendar.startOfDay(for: $0.date) }
        return grouped
            .map { (date: $0.key, entries: $0.value.sorted(by: { $0.date > $1.date })) }
            .sorted(by: { $0.date > $1.date })
    }

    private var todaysEntries: [FoodLogEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return logs.filter { calendar.isDate(calendar.startOfDay(for: $0.date), inSameDayAs: today) }
    }

    private func dayLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if let diff = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: Date())).day,
           diff > 6 {
            return Self.longDayFormatter.string(from: date)
        }
        return Self.dayFormatter.string(from: date)
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    private static let longDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()

    private var manualEntrySheet: some View {
        NavigationStack {
            Form {
                Section("Describe what you ate") {
                    TextEditor(text: $manualEntryText)
                        .frame(minHeight: 160)
                    TextField("Calories (optional)", text: $manualEntryCalories)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            .navigationTitle("Quick Log")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingManualEntry = false
                        manualEntryCalories = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let text = manualEntryText.trimmingCharacters(in: .whitespacesAndNewlines)
                        let caloriesInput = manualEntryCalories.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !text.isEmpty else { return }
                        showingManualEntry = false
                        manualEntryText = ""
                        manualEntryCalories = ""
                        Task { await handleManualEntry(text, caloriesInput: caloriesInput) }
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
        case "whole_foods", "vegetables", "lean_protein", "whole_grain", "fruit", 
             "salad", "healthy_fats", "fiber", "antioxidants", "vitamins", "minerals",
             "omega_3", "protein", "calcium", "iron", "vitamin_c", "vitamin_a",
             "folate", "potassium", "magnesium", "zinc", "selenium", "b_vitamins":
            return Color.green.opacity(0.2)
        case "ultra_processed", "added_sugar", "fried", "high_sodium", "saturated_fat",
             "trans_fat", "artificial_additives", "preservatives", "high_fructose_corn_syrup":
            return Color.red.opacity(0.15)
        default:
            return Color.blue.opacity(0.15)
        }
    }

    private func tagForeground(for tag: String) -> Color {
        switch tag {
        case "whole_foods", "vegetables", "lean_protein", "whole_grain", "fruit",
             "salad", "healthy_fats", "fiber", "antioxidants", "vitamins", "minerals",
             "omega_3", "protein", "calcium", "iron", "vitamin_c", "vitamin_a",
             "folate", "potassium", "magnesium", "zinc", "selenium", "b_vitamins":
            return Color.green
        case "ultra_processed", "added_sugar", "fried", "high_sodium", "saturated_fat",
             "trans_fat", "artificial_additives", "preservatives", "high_fructose_corn_syrup":
            return Color.red
        default:
            return Color.blue
        }
    }

    private func entryRow(for entry: FoodLogEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            HealthScoreBadge(score: entry.healthIndex, level: entry.healthLevel)
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

    private struct DailySummaryCard: View {
        let entries: [FoodLogEntry]
        let calorieGoal: Int

        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                header
                macroSection
                nutrientBadges
                scoreSection
                if !summary.highlights.isEmpty {
                    highlightsSection
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal)
        }

        private var summary: DailyNutritionSummary {
            let targets = NutritionTargets(calorieGoal: Double(max(calorieGoal, 1)))
            let aggregator = NutritionAggregator(targets: targets)
            return aggregator.summarize(entries: entries)
        }

        private var header: some View {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Today’s Nutrition")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(summary.calorieMacro.consumed.rounded())) / \(Int(summary.calorieMacro.target)) kcal")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if let overallConfidence = summary.confidence?.overall {
                    ConfidenceIndicator(level: overallConfidence)
                }
            }
        }

        private var macroSection: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text("Macro balance")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                MacroProgressRow(progress: summary.proteinMacro)
                MacroProgressRow(progress: summary.carbohydrateMacro)
                MacroProgressRow(progress: summary.fatMacro)
            }
        }

        private var nutrientBadges: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Key nutrients")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    NutrientBadge(title: "Fiber", detail: formatted(summary.fiberStatus.consumed, suffix: "g"), status: summary.fiberStatus.status)
                    NutrientBadge(title: "Added sugar", detail: formatted(summary.addedSugarStatus.consumed, suffix: "g"), status: summary.addedSugarStatus.status, inverse: true)
                    NutrientBadge(title: "Sodium", detail: formatted(summary.sodiumStatus.consumed, suffix: "mg"), status: summary.sodiumStatus.status, inverse: true)
                }
                HStack(spacing: 10) {
                    ServingsBadge(title: "Veg", consumed: summary.vegetableServings, target: summary.vegetableTarget)
                    ServingsBadge(title: "Fruit", consumed: summary.fruitServings, target: summary.fruitTarget)
                }
            }
        }

        private var scoreSection: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Diet quality")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(alignment: .center, spacing: 16) {
                    DietScoreBadge(score: summary.dietQuality, hasLoggedFood: !entries.isEmpty)
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(summary.dietQuality.components, id: \.name) { component in
                            DietComponentRow(component: component, hasLoggedFood: !entries.isEmpty)
                        }
                    }
                }
            }
        }

        private var highlightsSection: some View {
            VStack(alignment: .leading, spacing: 6) {
                Text("Highlights")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ForEach(summary.highlights, id: \.title) { highlight in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(highlight.title)
                            .font(.footnote)
                            .fontWeight(.semibold)
                        Text(highlight.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }

        private func formatted(_ value: Double, suffix: String) -> String {
            guard value.isFinite else { return "0 \(suffix)" }
            let number = Int(value.rounded())
            return "\(number) \(suffix)"
        }
    }
}

private struct ConfidenceIndicator: View {
    let level: Double

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: level >= 0.75 ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(level >= 0.75 ? .green : .orange)
            Text(levelText)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var levelText: String {
        switch level {
        case ..<0.4: return "Low confidence. Consider reviewing."
        case ..<0.75: return "Medium confidence."
        default: return "High confidence estimates."
        }
    }
}

private struct MacroProgressRow: View {
    let progress: DailyNutritionSummary.MacroProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(progress.label)
                    .font(.footnote)
                Spacer()
                Text("\(Int(progress.consumed.rounded())) / \(Int(progress.target.rounded())) \(progress.unit)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: safeProgress)
                .accentColor(colorForProgress(safeProgress))
        }
    }
    
    private var safeProgress: Double {
        let value = progress.progress
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }

    private func colorForProgress(_ value: Double) -> Color {
        guard value.isFinite else { return .orange }
        switch value {
        case ..<0.8: return .orange
        case ..<1.2: return .green
        default: return .red
        }
    }
}

private struct NutrientBadge: View {
    let title: String
    let detail: String
    let status: DailyNutritionSummary.NutrientStatus
    var inverse: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(detail)
                .font(.footnote)
                .fontWeight(.semibold)
            Text(statusText)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var statusText: String {
        switch status {
        case .inadequate:
            return inverse ? "Within limit" : "Below target"
        case .onTrack:
            return inverse ? "Within limit" : "On track"
        case .excessive:
            return inverse ? "Above limit" : "Above target"
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .onTrack:
            return Color.green.opacity(0.15)
        case .inadequate:
            return inverse ? Color.green.opacity(0.15) : Color.orange.opacity(0.15)
        case .excessive:
            return inverse ? Color.red.opacity(0.2) : Color.orange.opacity(0.15)
        }
    }
}

private struct ServingsBadge: View {
    let title: String
    let consumed: Double
    let target: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(consumedString) / \(Int(safeTarget))")
                .font(.footnote)
                .fontWeight(.semibold)
            Text(safeConsumed >= safeTarget ? "Goal met" : "Goal: \(Int(safeTarget))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(safeConsumed >= safeTarget ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
    
    private var safeConsumed: Double {
        consumed.isFinite ? consumed : 0
    }
    
    private var safeTarget: Double {
        target.isFinite ? target : 1
    }

    private var consumedString: String {
        String(format: "%.1f", safeConsumed)
    }
}

private struct DietScoreBadge: View {
    let score: DietQualityScore
    let hasLoggedFood: Bool

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            if hasLoggedFood {
                Text("\(score.total)")
                    .font(.system(size: 36, weight: .bold))
                Text("Grade \(score.grade)")
                    .font(.caption)
                    .fontWeight(.semibold)
                Text(score.topOpportunity)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            } else {
                Text("--")
                    .font(.system(size: 36, weight: .bold))
                Text("--")
                    .font(.caption)
                    .fontWeight(.semibold)
                Text("Log food to see your diet score")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(width: 130, height: 130)
        .background(hasLoggedFood ? LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing) : LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .foregroundStyle(hasLoggedFood ? .white : .secondary)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var gradientColors: [Color] {
        switch score.grade {
        case "A": return [.green, .teal]
        case "B": return [.blue, .green]
        case "C": return [.yellow, .orange]
        case "D": return [.orange, .red]
        default: return [.red, .pink]
        }
    }
}

private struct DietComponentRow: View {
    let component: DietQualityScore.Component
    let hasLoggedFood: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(component.name)
                    .font(.caption)
                Spacer()
                if hasLoggedFood {
                    Text(String(format: "%.0f%%", safeScore * 100))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text("N/A")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            if hasLoggedFood {
                ProgressView(value: safeProgress)
                    .accentColor(progressColor)
            } else {
                ProgressView(value: 0)
                    .accentColor(.gray.opacity(0.3))
            }
        }
    }
    
    private var safeScore: Double {
        component.score.isFinite ? component.score : 0
    }
    
    private var safeProgress: Double {
        let value = component.score
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }

    private var progressColor: Color {
        guard component.score.isFinite else { return .orange }
        switch component.score {
        case ..<0.6: return .red
        case ..<0.8: return .orange
        default: return .green
        }
    }
}

#Preview {
    NavigationStack { FoodLogView() }
}

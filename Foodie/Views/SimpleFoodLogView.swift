//
//  SimpleFoodLogView.swift
//  Foodie
//
//

import SwiftUI

struct SimpleFoodLogView: View {
    @StateObject private var voiceRecorder = VoiceRecordingService()
    @State private var logs: [FoodLogEntry] = FoodLogStore.shared.load().sorted(by: { $0.date > $1.date })
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showingRecordSheet = false
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    
                    if logs.isEmpty {
                        emptyState
                    } else {
                        logsList
                    }
                }
                .padding()
            }
            .background(AppTheme.background)
            
            // Floating voice button
            VStack {
                Spacer()
                voiceButton
                    .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showingRecordSheet) {
            VoiceRecordingSheet(
                voiceRecorder: voiceRecorder,
                isProcessing: $isProcessing,
                onComplete: { audioData in
                    await processVoiceLog(audioData)
                }
            )
        }
        .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What did you eat?")
                .font(.title).bold()
            Text("Just tap the mic and talk!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.circle")
                .font(.system(size: 60))
                .foregroundStyle(AppTheme.primary.opacity(0.6))
            
            Text("No meals logged yet")
                .font(.title3).bold()
            
            Text("Start logging your meals with voice.\nJust tap the mic and talk!")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
    
    private var logsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(groupedLogs, id: \.date) { group in
                VStack(alignment: .leading, spacing: 12) {
                    Text(dayLabel(for: group.date))
                        .font(.headline)
                        .padding(.horizontal, 4)
                    
                    ForEach(group.entries) { entry in
                        LogCard(entry: entry, onDelete: {
                            deleteEntry(entry)
                        })
                    }
                }
            }
        }
    }
    
    private var voiceButton: some View {
        Button {
            showingRecordSheet = true
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.primary, AppTheme.primary.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .shadow(color: AppTheme.primary.opacity(0.4), radius: 12, y: 6)
                
                Image(systemName: "mic.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .disabled(isProcessing)
    }
    
    private func processVoiceLog(_ audioData: Data) async {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            // 1. Transcribe audio
            let transcript = try await OpenAIClient().transcribeAudio(
                audioData: audioData,
                prompt: "The user is logging their meal. Listen for food items, portions, and meal details."
            )
            
            print("📝 [SimpleFoodLog] Transcript: \(transcript)")
            
            // 2. Parse food log
            let result = try await OpenAIClient().parseFoodLog(transcript: transcript)
            
            print("✅ [SimpleFoodLog] Parsed: \(result.summary)")
            
            // 3. Assess health
            let assessment = try await FoodHealthIndexer.shared.assess(summary: result.summary)
            
            // 4. Create nutrition breakdown
            let nutrition = extractNutritionBreakdown(from: result)
            
            // 5. Save entry
            let entry = FoodLogEntry(
                summary: result.summary,
                estimatedCalories: result.estimatedCalories,
                confidence: result.confidence,
                mealType: result.mealType,
                healthIndex: assessment.score,
                healthTags: assessment.tags,
                healthHighlights: assessment.highlights,
                nutrition: nutrition
            )
            
            await MainActor.run {
                logs.insert(entry, at: 0)
                logs.sort(by: { $0.date > $1.date })
                FoodLogStore.shared.save(logs)
                showingRecordSheet = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingRecordSheet = false
            }
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
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Voice Recording Sheet
private struct VoiceRecordingSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var voiceRecorder: VoiceRecordingService
    @Binding var isProcessing: Bool
    let onComplete: (Data) async -> Void
    
    @State private var recordedData: Data?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                visualizer
                
                statusText
                
                Spacer()
                
                actionButtons
            }
            .padding()
            .background(AppTheme.background)
            .navigationTitle("Log Your Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        voiceRecorder.cancelRecording()
                        dismiss()
                    }
                }
            }
        }
        .interactiveDismissDisabled(voiceRecorder.state == .recording || isProcessing)
    }
    
    private var visualizer: some View {
        ZStack {
            // Pulsing circles for recording
            if voiceRecorder.state == .recording {
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(AppTheme.primary.opacity(0.3), lineWidth: 2)
                        .frame(width: 120 + CGFloat(i) * 40, height: 120 + CGFloat(i) * 40)
                        .scaleEffect(voiceRecorder.state == .recording ? 1.0 : 0.8)
                        .opacity(voiceRecorder.state == .recording ? 0.0 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: false)
                            .delay(Double(i) * 0.3),
                            value: voiceRecorder.state
                        )
                }
            }
            
            // Center circle
            Circle()
                .fill(
                    voiceRecorder.state == .recording
                    ? LinearGradient(colors: [.red, .red.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    : LinearGradient(colors: [AppTheme.primary, AppTheme.primary.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: 120, height: 120)
                .shadow(color: (voiceRecorder.state == .recording ? Color.red : AppTheme.primary).opacity(0.4), radius: 20, y: 10)
            
            Image(systemName: voiceRecorder.state == .recording ? "waveform" : "mic.fill")
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
    
    private var statusText: some View {
        VStack(spacing: 8) {
            if isProcessing {
                Text("Processing...")
                    .font(.title3).bold()
                ProgressView()
            } else {
                switch voiceRecorder.state {
                case .idle:
                    Text("Ready to record")
                        .font(.title3).bold()
                    Text("Tap the mic to start")
                        .font(.body)
                        .foregroundStyle(.secondary)
                case .recording:
                    Text("Recording...")
                        .font(.title3).bold()
                    Text(formatDuration(voiceRecorder.recordingDuration))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.primary)
                case .processing:
                    Text("Processing...")
                        .font(.title3).bold()
                }
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 20) {
            if voiceRecorder.state == .idle && recordedData == nil {
                Button {
                    Task {
                        try? await voiceRecorder.startRecording()
                    }
                } label: {
                    Label("Start", systemImage: "mic.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            } else if voiceRecorder.state == .recording {
                Button {
                    Task {
                        do {
                            let data = try await voiceRecorder.stopRecording()
                            recordedData = data
                            Task {
                                await onComplete(data)
                            }
                        } catch {
                            print("❌ Failed to stop recording: \(error)")
                        }
                    }
                } label: {
                    Label("Done", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .disabled(isProcessing)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Log Card
private struct LogCard: View {
    let entry: FoodLogEntry
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.date, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let calories = entry.estimatedCalories {
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text("\(calories) cal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if let level = entry.healthLevel {
                    HealthScoreBadge(score: entry.healthIndex, level: level)
                }
            }
            
            Text(entry.summary)
                .font(.body)
            
            if let highlight = entry.healthHighlights?.first {
                Text(highlight)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    NavigationStack {
        SimpleFoodLogView()
    }
}


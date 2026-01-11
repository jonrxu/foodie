//
//  PlateFeedbackMockView.swift
//  Foodie
//
//  Step 3 mock: "plate feedback" screen (macros + coaching).
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct PlateFeedbackMockView: View {
    @State private var sampleIndex: Int = 0
    @State private var showingCopiedAlert = false

    private let samples: [PlateFeedbackSample] = [
        PlateFeedbackSample(
            mealName: "Chicken burrito bowl",
            mealDetails: "Rice, black beans, chicken, salsa, cheese",
            mealType: "Lunch",
            estimatedCalories: 660,
            carbsG: 92,
            proteinG: 34,
            fatG: 18,
            fiberG: 11,
            addedSugarG: 6,
            sodiumMg: 980,
            saturatedFatG: 7,
            healthScore: 64,
            healthGrade: "B",
            tags: ["High sodium", "Carb-heavy", "Good fiber"],
            whatWentWell: [
                "Nice mix of fiber + protein (beans + chicken).",
                "Solid meal volume if you add veggies."
            ],
            improvements: [
                "Carbs are doing most of the work — try a smaller rice portion.",
                "Sodium is high — watch sauces, cheese, and seasoning."
            ],
            smartSwaps: [
                "Swap half the rice for fajita veggies or lettuce.",
                "Choose salsa + pico over creamy sauces.",
                "Add a side fruit for more micronutrients."
            ],
            nextMealIdea: "For dinner: roasted salmon + veggies + small serving of rice (aim ~30–40g carbs).",
            items: [
                PlateFeedbackItem(name: "Rice", note: "Main carb source", carbsG: 60, proteinG: 5, fatG: 1),
                PlateFeedbackItem(name: "Black beans", note: "Fiber + protein", carbsG: 22, proteinG: 8, fatG: 1),
                PlateFeedbackItem(name: "Chicken", note: "Protein anchor", carbsG: 0, proteinG: 19, fatG: 5),
                PlateFeedbackItem(name: "Cheese", note: "Adds fat + sodium", carbsG: 1, proteinG: 2, fatG: 6),
                PlateFeedbackItem(name: "Salsa", note: "Low-cal flavor", carbsG: 9, proteinG: 0, fatG: 0)
            ],
            coachSummary: "It looks like 58% is carbohydrates — aim to include more veggies and a bit more lean protein next time."
        ),
        PlateFeedbackSample(
            mealName: "Salmon salad",
            mealDetails: "Salmon, mixed greens, avocado, olive oil",
            mealType: "Dinner",
            estimatedCalories: 610,
            carbsG: 22,
            proteinG: 38,
            fatG: 28,
            fiberG: 9,
            addedSugarG: 2,
            sodiumMg: 520,
            saturatedFatG: 6,
            healthScore: 86,
            healthGrade: "A",
            tags: ["High protein", "Heart-healthy fats", "Low sugar"],
            whatWentWell: [
                "Great protein base for satiety and recovery.",
                "Healthy fats (salmon + avocado) support fullness."
            ],
            improvements: [
                "If you need more energy, add a smart carb portion.",
                "Keep oils measured so calories don’t creep up."
            ],
            smartSwaps: [
                "Add berries or a small sweet potato for balanced carbs.",
                "Use lemon + herbs to reduce reliance on dressing.",
                "Add crunch with cucumbers/peppers instead of croutons."
            ],
            nextMealIdea: "For lunch: Greek yogurt bowl with fruit + nuts (aim ~25–35g protein).",
            items: [
                PlateFeedbackItem(name: "Salmon", note: "Protein + omega‑3", carbsG: 0, proteinG: 34, fatG: 18),
                PlateFeedbackItem(name: "Greens", note: "Volume + micronutrients", carbsG: 5, proteinG: 2, fatG: 0),
                PlateFeedbackItem(name: "Avocado", note: "Healthy fats + fiber", carbsG: 9, proteinG: 2, fatG: 10),
                PlateFeedbackItem(name: "Olive oil", note: "Adds fat quickly", carbsG: 0, proteinG: 0, fatG: 10),
                PlateFeedbackItem(name: "Veggies", note: "Fiber + crunch", carbsG: 8, proteinG: 0, fatG: 0)
            ],
            coachSummary: "Strong protein and healthy fats — if you want more energy, add a small carb like fruit or sweet potato."
        ),
        PlateFeedbackSample(
            mealName: "Pasta + marinara",
            mealDetails: "Pasta, marinara, parmesan",
            mealType: "Dinner",
            estimatedCalories: 720,
            carbsG: 110,
            proteinG: 18,
            fatG: 14,
            fiberG: 6,
            addedSugarG: 8,
            sodiumMg: 1180,
            saturatedFatG: 5,
            healthScore: 52,
            healthGrade: "C",
            tags: ["Very carb-heavy", "Low protein", "High sodium"],
            whatWentWell: [
                "Comfort meal — easy to improve with small additions."
            ],
            improvements: [
                "Protein is low — add a protein anchor.",
                "Fiber is low — add vegetables to slow digestion.",
                "Sodium is high — watch jar sauces and cheese."
            ],
            smartSwaps: [
                "Mix 50/50 regular + chickpea pasta.",
                "Add lentils or turkey to the sauce.",
                "Side salad + vinaigrette for fiber and micronutrients."
            ],
            nextMealIdea: "Next time: pasta with turkey + spinach + mushrooms (aim ≥25g protein).",
            items: [
                PlateFeedbackItem(name: "Pasta", note: "Main carbs", carbsG: 92, proteinG: 14, fatG: 2),
                PlateFeedbackItem(name: "Marinara", note: "Sodium + sugar varies", carbsG: 14, proteinG: 2, fatG: 3),
                PlateFeedbackItem(name: "Parmesan", note: "Flavor + sodium", carbsG: 4, proteinG: 2, fatG: 9)
            ],
            coachSummary: "Carbs are doing most of the work — aim to add a protein anchor and 2 cups of veggies for balance."
        )
    ]

    private var sample: PlateFeedbackSample { samples[sampleIndex % samples.count] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                flowCard
                headerCard
                scoreCard
                macrosCard
                nutrientsCard
                adviceCard
                itemsCard
                nextMealCard
                actionsCard

                Button {
                    sampleIndex = (sampleIndex + 1) % samples.count
                } label: {
                    Label("Try another example", systemImage: "arrow.triangle.2.circlepath")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.top, 4)
            }
            .padding()
        }
        .background(AppTheme.background)
        .navigationTitle("Plate Feedback")
        .navigationBarTitleDisplayMode(.inline)
        .mockupsFullscreen()
        .alert("Copied", isPresented: $showingCopiedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Coach feedback copied to clipboard.")
        }
    }

    private var flowCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Demo flow")
                .font(.headline)

            FlowStepRow(
                steps: [
                    FlowStep(title: "Nudge", subtitle: "Log your food"),
                    FlowStep(title: "Log", subtitle: "Talk to the mic"),
                    FlowStep(title: "Feedback", subtitle: "Your plate")
                ],
                activeIndex: 2
            )
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(AppTheme.primary.opacity(0.14))
                        .frame(width: 40, height: 40)
                    Image(systemName: "fork.knife")
                        .foregroundStyle(AppTheme.primary)
                        .font(.system(size: 16, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(sample.mealName)
                        .font(.title3).bold()
                    Text("\(sample.mealType) • \(sample.mealDetails)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var scoreCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Text("Overall")
                    .font(.headline)
                Spacer()
                HealthScoreBadge(score: sample.healthScore, level: sample.healthGrade)
            }

            Text(sample.coachSummary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if !sample.tags.isEmpty {
                let columns = [GridItem(.adaptive(minimum: 90), spacing: 8, alignment: .leading)]
                LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                    ForEach(sample.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Color(uiColor: .tertiarySystemFill))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var macrosCard: some View {
        let breakdown = MacroBreakdown(carbsG: sample.carbsG, proteinG: sample.proteinG, fatG: sample.fatG)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Macros")
                    .font(.headline)
                Spacer()
                Text("\(sample.estimatedCalories) cal (est.)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            DonutMacroChart(segments: breakdown.segments)

            VStack(spacing: 10) {
                MacroRow(
                    title: "Carbs",
                    grams: sample.carbsG,
                    percent: breakdown.carbsPercent,
                    color: .blue,
                    systemImage: "leaf"
                )
                MacroRow(
                    title: "Protein",
                    grams: sample.proteinG,
                    percent: breakdown.proteinPercent,
                    color: .green,
                    systemImage: "bolt"
                )
                MacroRow(
                    title: "Fat",
                    grams: sample.fatG,
                    percent: breakdown.fatPercent,
                    color: .orange,
                    systemImage: "drop.fill"
                )
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var nutrientsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key nutrition details")
                .font(.headline)

            VStack(spacing: 10) {
                MetricRow(title: "Fiber", value: "\(sample.fiberG)g", hint: "Aim ~25–35g/day", systemImage: "leaf.fill", color: .green)
                MetricRow(title: "Added sugar", value: "\(sample.addedSugarG)g", hint: "Keep it low when possible", systemImage: "cube.fill", color: .pink)
                MetricRow(title: "Sodium", value: "\(sample.sodiumMg)mg", hint: "Many people aim < 2,300mg/day", systemImage: "drop.triangle.fill", color: .orange)
                MetricRow(title: "Sat. fat", value: "\(sample.saturatedFatG)g", hint: "Balance with unsat. fats", systemImage: "flame.fill", color: .red)
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var adviceCard: some View {
        let breakdown = MacroBreakdown(carbsG: sample.carbsG, proteinG: sample.proteinG, fatG: sample.fatG)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Coach feedback")
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                if !sample.whatWentWell.isEmpty {
                    Text("What went well")
                        .font(.subheadline).bold()
                    ForEach(sample.whatWentWell, id: \.self) { text in
                        AdviceLine(systemImage: "checkmark.circle.fill", color: .green, text: text)
                    }
                }

                if !sample.improvements.isEmpty {
                    Divider().opacity(0.3)
                    Text("Opportunities")
                        .font(.subheadline).bold()
                    ForEach(sample.improvements, id: \.self) { text in
                        AdviceLine(systemImage: "wand.and.stars", color: AppTheme.primary, text: text)
                    }
                }

                if !sample.smartSwaps.isEmpty {
                    Divider().opacity(0.3)
                    Text("Smart swaps")
                        .font(.subheadline).bold()
                    ForEach(sample.smartSwaps, id: \.self) { text in
                        AdviceLine(systemImage: "arrow.left.arrow.right.circle.fill", color: .blue, text: text)
                    }
                }
            }

            Divider().opacity(0.3)

            Text("Summary")
                .font(.subheadline).bold()
                .foregroundStyle(.secondary)

            Text("It looks like \(breakdown.carbsPercent)% is carbohydrates, \(breakdown.proteinPercent)% is protein, and \(breakdown.fatPercent)% is fat.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var itemsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What we detected")
                .font(.headline)

            VStack(spacing: 10) {
                ForEach(sample.items) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(item.name)
                                .font(.subheadline).bold()
                            Spacer()
                            Text("\(item.carbsG)C  \(item.proteinG)P  \(item.fatG)F")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(item.note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color(uiColor: .tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var nextMealCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Next step")
                .font(.headline)
            AdviceLine(systemImage: "lightbulb.fill", color: .yellow, text: sample.nextMealIdea)
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var actionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions")
                .font(.headline)

            VStack(spacing: 10) {
                Button {
                    copyFeedbackToClipboard()
                    showingCopiedAlert = true
                } label: {
                    Label("Copy feedback", systemImage: "doc.on.doc")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(uiColor: .tertiarySystemFill))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Button {
                    // Demo-only placeholder
                } label: {
                    Label("Save as a template", systemImage: "bookmark.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(uiColor: .tertiarySystemFill))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func copyFeedbackToClipboard() {
        let breakdown = MacroBreakdown(carbsG: sample.carbsG, proteinG: sample.proteinG, fatG: sample.fatG)

        var lines: [String] = []
        lines.append("Plate feedback — \(sample.mealName)")
        lines.append("Macros: \(breakdown.carbsPercent)% C / \(breakdown.proteinPercent)% P / \(breakdown.fatPercent)% F")
        lines.append("Calories (est.): \(sample.estimatedCalories)")
        lines.append("Fiber: \(sample.fiberG)g, Added sugar: \(sample.addedSugarG)g, Sodium: \(sample.sodiumMg)mg")
        lines.append("")
        lines.append("What went well:")
        lines.append(contentsOf: sample.whatWentWell.map { "- \($0)" })
        lines.append("")
        lines.append("Opportunities:")
        lines.append(contentsOf: sample.improvements.map { "- \($0)" })
        lines.append("")
        lines.append("Smart swaps:")
        lines.append(contentsOf: sample.smartSwaps.map { "- \($0)" })

        #if canImport(UIKit)
        UIPasteboard.general.string = lines.joined(separator: "\n")
        #endif
    }
}

private struct PlateFeedbackSample {
    let mealName: String
    let mealDetails: String
    let mealType: String
    let estimatedCalories: Int
    let carbsG: Int
    let proteinG: Int
    let fatG: Int
    let fiberG: Int
    let addedSugarG: Int
    let sodiumMg: Int
    let saturatedFatG: Int
    let healthScore: Int
    let healthGrade: String
    let tags: [String]
    let whatWentWell: [String]
    let improvements: [String]
    let smartSwaps: [String]
    let nextMealIdea: String
    let items: [PlateFeedbackItem]
    let coachSummary: String
}

private struct PlateFeedbackItem: Identifiable {
    let id = UUID()
    let name: String
    let note: String
    let carbsG: Int
    let proteinG: Int
    let fatG: Int
}

private struct MacroBreakdown {
    let carbsG: Int
    let proteinG: Int
    let fatG: Int

    private var carbsCalories: Int { carbsG * 4 }
    private var proteinCalories: Int { proteinG * 4 }
    private var fatCalories: Int { fatG * 9 }

    var totalCalories: Int { max(1, carbsCalories + proteinCalories + fatCalories) }

    var carbsPercent: Int { Int(round(100.0 * Double(carbsCalories) / Double(totalCalories))) }
    var proteinPercent: Int { Int(round(100.0 * Double(proteinCalories) / Double(totalCalories))) }
    var fatPercent: Int {
        let remaining = 100 - carbsPercent - proteinPercent
        return max(0, remaining)
    }

    var segments: [MacroSegment] {
        [
            MacroSegment(title: "Carbs", fraction: Double(carbsPercent) / 100.0, color: .blue),
            MacroSegment(title: "Protein", fraction: Double(proteinPercent) / 100.0, color: .green),
            MacroSegment(title: "Fat", fraction: Double(fatPercent) / 100.0, color: .orange)
        ]
    }
}

private struct MacroSegment: Identifiable {
    let id = UUID()
    let title: String
    let fraction: Double
    let color: Color
}

private struct DonutMacroChart: View {
    let segments: [MacroSegment]

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color(uiColor: .separator).opacity(0.15), lineWidth: 14)

                ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                    Circle()
                        .trim(from: startTrim(for: index), to: endTrim(for: index))
                        .stroke(segment.color, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
            }
            .frame(width: 84, height: 84)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(segments) { segment in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(segment.color)
                            .frame(width: 10, height: 10)
                        Text(segment.title)
                            .font(.subheadline).bold()
                        Spacer()
                        Text("\(Int(round(segment.fraction * 100)))%")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(uiColor: .tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func startTrim(for index: Int) -> CGFloat {
        let prior = segments.prefix(index).reduce(0.0) { $0 + $1.fraction }
        return CGFloat(prior)
    }

    private func endTrim(for index: Int) -> CGFloat {
        let prior = segments.prefix(index + 1).reduce(0.0) { $0 + $1.fraction }
        return CGFloat(prior)
    }
}

private struct MacroRow: View {
    let title: String
    let grams: Int
    let percent: Int
    let color: Color
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 18)

            Text(title)
                .font(.subheadline).bold()
                .frame(width: 70, alignment: .leading)

            Spacer()

            Text("\(grams)g")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("\(percent)%")
                .font(.subheadline).bold()
                .foregroundStyle(color)
                .frame(width: 48, alignment: .trailing)
        }
        .padding(.vertical, 2)
    }
}

private struct MetricRow: View {
    let title: String
    let value: String
    let hint: String
    let systemImage: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 18)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.subheadline).bold()
                    Spacer()
                    Text(value)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text(hint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct FlowStep: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
}

private struct FlowStepRow: View {
    let steps: [FlowStep]
    let activeIndex: Int

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { idx, step in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(idx <= activeIndex ? AppTheme.primary : Color(uiColor: .separator).opacity(0.35))
                            .frame(width: 10, height: 10)
                        Text(step.title)
                            .font(.subheadline).bold()
                            .foregroundStyle(idx == activeIndex ? .primary : .secondary)
                    }
                    Text(step.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

#Preview {
    NavigationStack {
        PlateFeedbackMockView()
    }
}



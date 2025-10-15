//
//  OnboardingFlowView.swift
//  Foodie
//
//  Created by AI Assistant.
//

import SwiftUI

struct OnboardingFlowView: View {
    enum Step: Int, CaseIterable {
        case welcome
        case nameAndGoal
        case dietaryStyles
        case allergies
        case goals
        case preferences
        case summary

        var title: String {
            switch self {
            case .welcome: return "Welcome"
            case .nameAndGoal: return "Your basics"
            case .dietaryStyles: return "Eating style"
            case .allergies: return "Allergies"
            case .goals: return "Your goals"
            case .preferences: return "Lifestyle"
            case .summary: return "You’re set"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: AppSession
    @State private var step: Step = .welcome
    @State private var draftProfile: UserProfile

    private let cuisineSuggestions = [
        "Mediterranean",
        "Italian comfort",
        "Thai takeout",
        "Latin flavors",
        "Plant-based bowls",
        "BBQ & grill",
        "Japanese",
        "Indian curries"
    ]

    private let budgetSuggestions = [
        "Groceries under $60/week",
        "Prefer bulk warehouse runs",
        "Keep takeout under $30",
        "Family meals on a budget"
    ]

    private let timeSuggestions = [
        "15-minute dinners",
        "Batch cook on Sundays",
        "Slow cooker midweek",
        "No oven on weekdays"
    ]

    init(profile: UserProfile? = nil) {
        _draftProfile = State(initialValue: profile ?? UserProfile())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressHeader
                TabView(selection: $step) {
                    welcomeStep
                        .tag(Step.welcome)
                    nameStep
                        .tag(Step.nameAndGoal)
                    dietaryStep
                        .tag(Step.dietaryStyles)
                    allergyStep
                        .tag(Step.allergies)
                    goalsStep
                        .tag(Step.goals)
                    preferencesStep
                        .tag(Step.preferences)
                    summaryStep
                        .tag(Step.summary)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .background(AppTheme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if step != .welcome {
                        Button("Back") { goBack() }
                    }
                }
            }
        }
        .onAppear { syncDraftFromSession() }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(step.title)
                    .font(.title).bold()
                Spacer()
                Text("Step \(step.rawValue + 1) of \(Step.allCases.count)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: Double(step.rawValue + 1), total: Double(Step.allCases.count))
                .accentColor(AppTheme.primary)
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .padding(.bottom, 16)
    }

    private var welcomeStep: some View {
        VStack(spacing: 28) {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(AppTheme.primary)
                Text("Let’s personalize Foodie")
                    .font(.title2).bold()
                Text("A few quick questions will tailor your plan and grocery tips. You can tweak anything later.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            VStack(spacing: 16) {
                Button {
                    step = .nameAndGoal
                } label: {
                    Text("Let’s get started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                Button {
                    session.beginAuthentication()
                    // TODO: Integrate Google Sign-In SDK here. For now, simulate success.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        session.finishAuthentication(email: "user@example.com")
                        step = .nameAndGoal
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "g.circle")
                            .font(.system(size: 22, weight: .regular))
                        if session.isAuthenticating {
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                        Text("Continue with Google")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .disabled(session.isAuthenticating)
            }
            .padding(.horizontal, 24)
            Spacer()
        }
    }

    private var nameStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            description("We’ll use your name in coaching and summaries.")
            TextField("Preferred name", text: Binding(
                get: { draftProfile.displayName },
                set: { draftProfile.displayName = $0 }
            ))
            .textFieldStyle(.roundedBorder)

            Stepper(value: Binding(
                get: { draftProfile.dailyCalorieGoal ?? 2000 },
                set: { draftProfile.dailyCalorieGoal = $0 }
            ), in: 1200...4000, step: 50) {
                Text("Daily calorie target: \(draftProfile.dailyCalorieGoal ?? 2000) kcal")
            }

            Spacer()
            primaryButton(title: "Continue", disabled: draftProfile.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                goForward()
            }
        }
        .padding(24)
    }

    private var dietaryStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            description("Pick a dietary style (or a few). Add notes if there’s something special.")
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(UserProfile.DietaryStyle.allCases) { style in
                        SelectableChip(title: style.displayName, isSelected: draftProfile.dietaryStyles.contains(style)) {
                            toggle(style)
                        }
                    }
                }
            }
            TextField("Anything else we should know?", text: Binding(
                get: { draftProfile.customDietaryNotes },
                set: { draftProfile.customDietaryNotes = $0 }
            ), axis: .vertical)
            .frame(minHeight: 80)
            .textFieldStyle(.roundedBorder)

            Spacer()
            primaryButton(title: "Continue", disabled: draftProfile.dietaryStyles.isEmpty && draftProfile.customDietaryNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                goForward()
            }
        }
        .padding(24)
    }

    private var allergyStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            description("Call out any allergies or avoidances so we can keep suggestions safe.")
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(UserProfile.AllergyTag.allCases) { tag in
                        SelectableChip(title: tag.displayName, isSelected: draftProfile.allergyTags.contains(tag)) {
                            toggle(tag)
                        }
                    }
                }
            }

            TextField("Other notes (optional)", text: Binding(
                get: { draftProfile.customAllergyNotes },
                set: { draftProfile.customAllergyNotes = $0 }
            ))
            .textFieldStyle(.roundedBorder)

            Spacer()
            primaryButton(title: "Continue") { goForward() }
        }
        .padding(24)
    }

    private var goalsStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            description("Tell Foodie what matters most so coaching stays focused.")
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(UserProfile.HealthGoal.allCases) { goal in
                        SelectableChip(title: goal.displayName, isSelected: draftProfile.healthGoals.contains(goal)) {
                            toggle(goal)
                        }
                    }
                }
            }

            Spacer()
            primaryButton(title: "Continue", disabled: draftProfile.healthGoals.isEmpty) { goForward() }
        }
        .padding(24)
    }

    private var preferencesStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                description("Anything about budget, time, or cuisines we should factor in?")

                VStack(alignment: .leading, spacing: 12) {
                    Text("Favorite cuisines")
                        .font(.headline)
                    
                    WrappingHStack(items: cuisineSuggestions) { suggestion in
                        SuggestionChip(title: suggestion) { addCuisine(suggestion) }
                    }
                    
                    TagsEditor(tags: Binding(
                        get: { draftProfile.favoriteCuisines },
                        set: { draftProfile.favoriteCuisines = $0 }
                    ))
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Budget notes")
                        .font(.headline)
                    
                    WrappingHStack(items: budgetSuggestions) { suggestion in
                        SuggestionChip(title: suggestion) { setBudgetSuggestion(suggestion) }
                    }
                    
                    TextField("E.g. groceries under $80/week", text: Binding(
                        get: { draftProfile.groceryBudgetNotes },
                        set: { draftProfile.groceryBudgetNotes = $0 }
                    ), axis: .vertical)
                    .padding(12)
                    .background(AppTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Time & prep")
                        .font(.headline)
                    
                    WrappingHStack(items: timeSuggestions) { suggestion in
                        SuggestionChip(title: suggestion) { setTimeSuggestion(suggestion) }
                    }
                    
                    TextField("E.g. 20 min dinners, batch cook Sundays", text: Binding(
                        get: { draftProfile.cookingTimeNotes },
                        set: { draftProfile.cookingTimeNotes = $0 }
                    ), axis: .vertical)
                    .padding(12)
                    .background(AppTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(24)
            .padding(.bottom, 140)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                primaryButton(title: "Continue") { goForward() }
                    .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            .background(.ultraThinMaterial)
        }
    }

    private var summaryStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Profile")
                SummaryRow(label: "Name", value: draftProfile.displayName)
                SummaryRow(label: "Calorie target", value: "\(draftProfile.dailyCalorieGoal ?? 2000) kcal")

                SectionHeader(title: "Diet & allergies")
                SummaryRow(label: "Diet", value: draftProfile.dietarySummary.ifEmpty("Not specified"))
                SummaryRow(label: "Allergies", value: draftProfile.allergySummary.ifEmpty("None noted"))

                SectionHeader(title: "Goals")
                SummaryRow(label: nil, value: draftProfile.goalsSummary.ifEmpty("Stay balanced"))

                SectionHeader(title: "Lifestyle")
                SummaryRow(label: "Cuisines", value: draftProfile.favoriteCuisinesSummary.ifEmpty("Explore new things"))
                SummaryRow(label: "Notes", value: draftProfile.lifestyleSummary.ifEmpty("No extra notes"))
            }
            .padding(24)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                Button {
                    completeOnboarding()
                } label: {
                    Text("Finish setup")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                Button("Back") { goBack() }
                    .padding(.bottom, 12)
            }
            .padding(.horizontal, 24)
            .background(.ultraThinMaterial)
        }
    }

    private func goForward() {
        guard let next = Step(rawValue: step.rawValue + 1) else { return }
        step = next
    }

    private func goBack() {
        guard let prev = Step(rawValue: step.rawValue - 1) else { return }
        step = prev
    }

    private func completeOnboarding() {
        if draftProfile.joinedDate == .distantPast {
            draftProfile.joinedDate = Date()
        }
        session.updateProfile { profile in
            profile = draftProfile
        }
        session.completeOnboarding()
        dismiss()
    }

    private func syncDraftFromSession() {
        if let existing = session.profile {
            draftProfile = existing
        }
    }

    private func toggle(_ style: UserProfile.DietaryStyle) {
        if let idx = draftProfile.dietaryStyles.firstIndex(of: style) {
            draftProfile.dietaryStyles.remove(at: idx)
        } else {
            draftProfile.dietaryStyles.append(style)
        }
    }

    private func toggle(_ tag: UserProfile.AllergyTag) {
        if let idx = draftProfile.allergyTags.firstIndex(of: tag) {
            draftProfile.allergyTags.remove(at: idx)
        } else {
            draftProfile.allergyTags.append(tag)
        }
    }

    private func toggle(_ goal: UserProfile.HealthGoal) {
        if let idx = draftProfile.healthGoals.firstIndex(of: goal) {
            draftProfile.healthGoals.remove(at: idx)
        } else {
            draftProfile.healthGoals.append(goal)
        }
    }

    private func addCuisine(_ cuisine: String) {
        if draftProfile.favoriteCuisines.contains(where: { $0.caseInsensitiveCompare(cuisine) == .orderedSame }) == false {
            draftProfile.favoriteCuisines.append(cuisine)
        }
    }

    private func setBudgetSuggestion(_ text: String) {
        draftProfile.groceryBudgetNotes = text
    }

    private func setTimeSuggestion(_ text: String) {
        draftProfile.cookingTimeNotes = text
    }

    private func description(_ text: String) -> some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(.secondary)
    }

    private func primaryButton(title: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(disabled ? AppTheme.primary.opacity(0.3) : AppTheme.primary)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(disabled)
    }
}

private struct SelectableChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? AppTheme.primary.opacity(0.15) : Color(uiColor: .secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? AppTheme.primary : Color(uiColor: .separator), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct TagsEditor: View {
    @Binding var tags: [String]
    @State private var newTag: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !tags.isEmpty {
                WrappingHStack(items: tags) { tag in
                    HStack(spacing: 6) {
                        Text(tag)
                        Button(action: { remove(tag) }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(AppTheme.primary.opacity(0.12))
                    .clipShape(Capsule())
                }
            }

            HStack {
                TextField("Add another", text: $newTag)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    appendTag()
                }
                .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func appendTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }
        if tags.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) == false {
            tags.append(trimmed)
        }
        newTag = ""
    }

    private func remove(_ tag: String) {
        tags.removeAll { $0.caseInsensitiveCompare(tag) == .orderedSame }
    }
}

private struct SuggestionChip: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(AppTheme.primary.opacity(0.12))
                .foregroundStyle(AppTheme.primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
    }
}

private struct SummaryRow: View {
    let label: String?
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let label {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct WrappingHStack<Item: Hashable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(items.chunked(into: 2)), id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { item in
                        content(item)
                    }
                    Spacer()
                }
            }
        }
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : self
    }
}


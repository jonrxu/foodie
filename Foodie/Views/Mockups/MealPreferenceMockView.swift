//
//  MealPreferenceMockView.swift
//  Foodie
//
//  Mock: meal preferences selection.
//

import SwiftUI

struct MealPreferenceMockView: View {
    @State private var selectedFocus: Set<MealFocus> = [.balancedPlates]
    @State private var selectedMealTypes: Set<MealType> = [.lunch, .dinner]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("What type of meals do you want?")
                    .font(.title3).bold()

                focusList

                Text("What type of meals do you want?")
                    .font(.subheadline).bold()
                    .padding(.top, 6)

                mealTypeChips
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                Button {
                    // Demo-only
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.primary)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(uiColor: .systemBackground))
        }
        .background(AppTheme.background)
        .navigationTitle("Meal Preferences")
        .navigationBarTitleDisplayMode(.inline)
        .mockupsFullscreen()
        .navigationBarBackButtonHidden(true)
    }

    private var focusList: some View {
        VStack(spacing: 12) {
            ForEach(MealFocus.allCases, id: \.self) { focus in
                FocusRow(
                    title: focus.title,
                    subtitle: focus.subtitle,
                    emoji: focus.emoji,
                    isSelected: selectedFocus.contains(focus)
                ) {
                    toggleFocus(focus)
                }
            }
        }
    }

    private var mealTypeChips: some View {
        HStack(spacing: 10) {
            ForEach(MealType.allCases, id: \.self) { type in
                ChipButton(title: type.title, isSelected: selectedMealTypes.contains(type)) {
                    toggleMealType(type)
                }
            }
        }
    }

    private func toggleFocus(_ focus: MealFocus) {
        if selectedFocus.contains(focus) {
            selectedFocus.remove(focus)
        } else {
            selectedFocus.insert(focus)
        }
    }

    private func toggleMealType(_ type: MealType) {
        if selectedMealTypes.contains(type) {
            selectedMealTypes.remove(type)
        } else {
            selectedMealTypes.insert(type)
        }
    }
}

private enum MealFocus: CaseIterable {
    case lowGlycemic
    case highFiber
    case leanProtein
    case nonStarchyVeg
    case balancedPlates

    var title: String {
        switch self {
        case .lowGlycemic: return "Low Glycemic Index Meals"
        case .highFiber: return "High-Fiber Dishes"
        case .leanProtein: return "Lean Protein & Healthy Fats"
        case .nonStarchyVeg: return "Non-Starchy Vegetables Focused"
        case .balancedPlates: return "Balanced Plates"
        }
    }

    var subtitle: String {
        switch self {
        case .lowGlycemic: return "Slow-digesting carbs for stable blood sugar"
        case .highFiber: return "Promotes fullness and aids digestion"
        case .leanProtein: return "Supports muscle health and satiety"
        case .nonStarchyVeg: return "Nutrient-dense with minimal carb impact"
        case .balancedPlates: return "The ideal mix for overall health"
        }
    }

    var emoji: String {
        switch self {
        case .lowGlycemic: return "🍃"
        case .highFiber: return "🥣"
        case .leanProtein: return "🥑"
        case .nonStarchyVeg: return "🥦"
        case .balancedPlates: return "🥗"
        }
    }
}

private enum MealType: CaseIterable {
    case breakfast
    case lunch
    case dinner
    case snacks

    var title: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snacks: return "Snacks"
        }
    }
}

private struct FocusRow: View {
    let title: String
    let subtitle: String
    let emoji: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(emoji)
                    .font(.title3)
                    .frame(width: 34, height: 34)
                    .background(Color(uiColor: .tertiarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline).bold()
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.primary)
                }
            }
            .padding(14)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? AppTheme.primary : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ChipButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(isSelected ? .white : .secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(isSelected ? AppTheme.primary : Color(uiColor: .tertiarySystemFill))
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        MealPreferenceMockView()
    }
}

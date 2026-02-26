//
//  DinnerMealSelectionMockView.swift
//  Foodie
//
//  Mockup: meal type selection + dinner meal bank with add-to-cart buttons.
//

import SwiftUI

struct DinnerMealSelectionMockView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var addedMealIDs: Set<UUID> = []

    private let mealTypeTitles = ["Breakfast", "Lunch", "Dinner", "Snacks"]

    private let dinnerMeals: [DinnerMealOption] = [
        DinnerMealOption(
            title: "Balanced dinner",
            subtitle: "A little bit of everything",
            imageName: "balanced"
        ),
        DinnerMealOption(
            title: "Fiber-rich dinner",
            subtitle: "Stay full longer",
            imageName: "highfiber"
        ),
        DinnerMealOption(
            title: "Veggie focus",
            subtitle: "More veggies",
            imageName: "nonstarchy"
        ),
        DinnerMealOption(
            title: "Lower sugar",
            subtitle: "Gentler rise",
            imageName: "lowglycemic"
        )
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                mockupBackground
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What meals do you want?")
                            .font(.system(size: 33, weight: .bold, design: .rounded))
                        Text("Choose your meal type, then add options to your cart")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 14)

                    mealTypeRow

                    Spacer(minLength: 14)

                    mealBankCard
                        .contentShape(Rectangle())
                        .onTapGesture {
                            dismiss()
                        }
                }
                .padding(.horizontal, 20)
                .padding(.top, 62)
                .padding(.bottom, 24)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
                .contentShape(Rectangle())
                .onTapGesture {
                    dismiss()
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .mockupsFullscreen()
        .navigationBarBackButtonHidden(true)
    }

    private var mealTypeRow: some View {
        HStack(spacing: 10) {
            ForEach(mealTypeTitles, id: \.self) { title in
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(title == "Dinner" ? .white : .secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(title == "Dinner" ? AppTheme.primary : Color(uiColor: .tertiarySystemFill))
                    )
            }
        }
    }

    private var mealBankCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dinner options")
                .font(.headline)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12, alignment: .top),
                    GridItem(.flexible(), spacing: 12, alignment: .top)
                ],
                spacing: 12
            ) {
                ForEach(dinnerMeals) { meal in
                    DinnerMealCard(
                        meal: meal,
                        isAdded: addedMealIDs.contains(meal.id)
                    ) {
                        if addedMealIDs.contains(meal.id) {
                            addedMealIDs.remove(meal.id)
                        } else {
                            addedMealIDs.insert(meal.id)
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                }
            }
        }
        .padding(16)
        .background(.white.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.blue.opacity(0.12), lineWidth: 1)
        )
    }

    private var mockupBackground: some View {
        ZStack {
            Color.white

            LinearGradient(
                colors: [
                    .white,
                    .white,
                    Color.blue.opacity(0.003),
                    Color.blue.opacity(0.012)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [Color.blue.opacity(0.012), Color.blue.opacity(0.0)],
                center: UnitPoint(x: 0.5, y: 0.8),
                startRadius: 60,
                endRadius: 520
            )
        }
    }
}

private struct DinnerMealOption: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let imageName: String
}

private struct DinnerMealCard: View {
    let meal: DinnerMealOption
    let isAdded: Bool
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(meal.imageName)
                .resizable()
                .scaledToFill()
                .frame(height: 90)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(meal.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text(meal.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)

            Button(action: action) {
                Label(isAdded ? "Added" : "Add to cart", systemImage: isAdded ? "checkmark.circle.fill" : "cart.badge.plus")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isAdded ? Color.green : AppTheme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        DinnerMealSelectionMockView()
    }
}

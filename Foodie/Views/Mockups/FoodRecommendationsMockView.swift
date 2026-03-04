//
//  FoodRecommendationsMockView.swift
//  Foodie
//
//  CGM demo (Slide 3): food recommendations with "Add to cart" actions (visuals only).
//

import SwiftUI

struct FoodRecommendationsMockView: View {
    @State private var added: Set<String> = []
    @Environment(\.dismiss) private var dismiss

    private let recs: [CGMFoodRecommendationMock] = [
        CGMFoodRecommendationMock(
            title: "Greek yogurt + berries",
            subtitle: "High protein + fiber",
            reason: "Tends to produce a gentler post‑meal rise vs. refined carbs.",
            impactLabel: "Low spike",
            impactColor: .green,
            tags: ["Protein", "Quick"],
            cartItems: ["Greek yogurt", "Blueberries"]
        ),
        CGMFoodRecommendationMock(
            title: "Chicken + veggie stir‑fry",
            subtitle: "Protein-forward dinner",
            reason: "More volume + protein can reduce overnight highs.",
            impactLabel: "Steadier",
            impactColor: .blue,
            tags: ["Dinner", "Meal prep"],
            cartItems: ["Chicken", "Broccoli", "Bell peppers"]
        ),
        CGMFoodRecommendationMock(
            title: "Oats + chia + cinnamon",
            subtitle: "Slow-digesting breakfast",
            reason: "Soluble fiber may reduce the size of spikes.",
            impactLabel: "Moderate",
            impactColor: .orange,
            tags: ["Breakfast", "Fiber"],
            cartItems: ["Oats", "Chia", "Cinnamon"]
        )
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard
                recommendationsList
                viewCartButton
            }
            .padding()
        }
        .background(AppTheme.background)
        .navigationTitle("Recommendations")
        .navigationBarTitleDisplayMode(.inline)
        .mockupsFullscreen()
        .navigationBarBackButtonHidden(true)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppTheme.primary.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Food recommendations")
                        .font(.headline)
                    Text("Simple picks to help keep you in range")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var recommendationsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommended foods")
                .font(.headline)

            VStack(spacing: 12) {
                ForEach(recs) { rec in
                    RecommendationCard(
                        rec: rec,
                        isAdded: added.contains(rec.id),
                        onAdd: {
                            if added.contains(rec.id) {
                                added.remove(rec.id)
                            } else {
                                added.insert(rec.id)
                            }
                        }
                    )
                }
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var viewCartButton: some View {
        Button {
            dismiss()
        } label: {
            Label("View cart", systemImage: "cart.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppTheme.primary)
                .foregroundStyle(.white)
                .clipShape(Capsule())
        }
        .padding(.top, 4)
    }
}

private struct CGMFoodRecommendationMock: Identifiable {
    var id: String { title }
    let title: String
    let subtitle: String
    let reason: String
    let impactLabel: String
    let impactColor: Color
    let tags: [String]
    let cartItems: [String]
}

private struct RecommendationCard: View {
    let rec: CGMFoodRecommendationMock
    let isAdded: Bool
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(rec.impactColor.opacity(0.14))
                        .frame(width: 44, height: 44)
                    Image(systemName: "fork.knife")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(rec.impactColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(rec.title)
                        .font(.subheadline).bold()
                    Text(rec.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(rec.impactLabel)
                    .font(.caption2).bold()
                    .foregroundStyle(rec.impactColor)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(rec.impactColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            Text(rec.reason)
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(rec.cartItems.prefix(2), id: \.self) { item in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color(uiColor: .tertiaryLabel))
                        Text(item)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Button(action: onAdd) {
                Label(isAdded ? "Added" : "Add to cart", systemImage: isAdded ? "checkmark" : "plus")
                    .font(.subheadline).bold()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isAdded ? Color.green : AppTheme.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(12)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(uiColor: .separator).opacity(0.45), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        FoodRecommendationsMockView()
    }
}

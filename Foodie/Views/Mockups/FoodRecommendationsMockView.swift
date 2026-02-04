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
                summaryCard
                recommendationsList
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
                    Text("Healthy eating ideas")
                        .font(.headline)
                    Text("Based on your CGM patterns this week")
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

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Coach summary (mock)")
                .font(.headline)

            AdviceLine(systemImage: "sparkles", color: AppTheme.primary, text: "You’re mostly in range, but dinner tends to spike higher. Let’s bias toward protein + fiber at night.")

            Divider().opacity(0.25)

            HStack(spacing: 10) {
                Pill(text: "Low spike", color: .green)
                Pill(text: "High protein", color: .blue)
                Pill(text: "Fiber-friendly", color: .orange)
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
                        },
                        onDetails: {
                            dismiss()
                        }
                    )
                }

                Button {
                    dismiss()
                } label: {
                    Label("View cart", systemImage: "cart.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func tap(_ name: String) {
        dismiss()
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
    let onDetails: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                    .font(.caption).bold()
                    .foregroundStyle(rec.impactColor)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(rec.impactColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            Text(rec.reason)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            let columns = [GridItem(.adaptive(minimum: 84), spacing: 8, alignment: .leading)]
            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(rec.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption).bold()
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color(uiColor: .tertiarySystemFill))
                        .clipShape(Capsule())
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(rec.cartItems, id: \.self) { item in
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
            .padding(10)
            .background(Color(uiColor: .tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            HStack(spacing: 10) {
                Button(action: onAdd) {
                    Label(isAdded ? "Added" : "Add to cart", systemImage: isAdded ? "checkmark" : "plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isAdded ? Color.green : AppTheme.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Button(action: onDetails) {
                    Label("Details", systemImage: "info.circle")
                        .font(.headline)
                        .frame(width: 120)
                        .padding(.vertical, 12)
                        .background(Color(uiColor: .tertiarySystemFill))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct Pill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption).bold()
            .foregroundStyle(color)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        FoodRecommendationsMockView()
    }
}

//
//  GroceryCartMockView.swift
//  Foodie
//
//  Mock grocery cart screen with a sample generated cart (visuals only).
//

import SwiftUI

struct GroceryCartMockView: View {
    @State private var showingMockAlert = false
    @State private var lastTapped: String = "Action"

    private let cart = SampleCart(
        title: "Generated cart",
        subtitle: "High-protein week • 5 days",
        storeName: "Whole Foods (pickup)",
        etaText: "Ready in ~2 hours",
        items: [
            SampleCartItem(name: "Chicken breast", detail: "2 lb", category: "Protein", systemImage: "bolt.fill"),
            SampleCartItem(name: "Greek yogurt", detail: "32 oz", category: "Protein", systemImage: "bolt.fill"),
            SampleCartItem(name: "Eggs", detail: "18 ct", category: "Protein", systemImage: "bolt.fill"),
            SampleCartItem(name: "Salmon fillets", detail: "1.5 lb", category: "Protein", systemImage: "bolt.fill"),

            SampleCartItem(name: "Brown rice", detail: "2 lb", category: "Carbs", systemImage: "leaf.fill"),
            SampleCartItem(name: "Sweet potatoes", detail: "3 lb", category: "Carbs", systemImage: "leaf.fill"),
            SampleCartItem(name: "Old‑fashioned oats", detail: "42 oz", category: "Carbs", systemImage: "leaf.fill"),

            SampleCartItem(name: "Broccoli", detail: "2 heads", category: "Produce", systemImage: "carrot.fill"),
            SampleCartItem(name: "Mixed greens", detail: "10 oz", category: "Produce", systemImage: "carrot.fill"),
            SampleCartItem(name: "Bell peppers", detail: "3 ct", category: "Produce", systemImage: "carrot.fill"),
            SampleCartItem(name: "Bananas", detail: "6 ct", category: "Produce", systemImage: "carrot.fill"),
            SampleCartItem(name: "Blueberries", detail: "12 oz", category: "Produce", systemImage: "carrot.fill"),

            SampleCartItem(name: "Olive oil", detail: "16.9 oz", category: "Pantry", systemImage: "drop.fill"),
            SampleCartItem(name: "Black beans", detail: "4 cans", category: "Pantry", systemImage: "drop.fill"),
            SampleCartItem(name: "Salsa", detail: "16 oz", category: "Pantry", systemImage: "drop.fill"),
            SampleCartItem(name: "Almonds", detail: "12 oz", category: "Pantry", systemImage: "drop.fill"),

            SampleCartItem(name: "Sparkling water", detail: "12 pack", category: "Extras", systemImage: "sparkles"),
            SampleCartItem(name: "Dark chocolate", detail: "70% • 3 bars", category: "Extras", systemImage: "sparkles")
        ],
        notes: [
            "Balanced macros: protein-forward, fiber-friendly.",
            "Swaps: chicken → tofu, salmon → canned tuna, blueberries → apples.",
            "Budget tip: buy frozen broccoli + mixed berries."
        ]
    )

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard
                checkoutCard
                itemsCard
                notesCard
            }
            .padding()
        }
        .background(AppTheme.background)
        .navigationTitle("Grocery Cart")
        .navigationBarTitleDisplayMode(.inline)
        .mockupsFullscreen()
        .alert("Mock only", isPresented: $showingMockAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("\(lastTapped) is a demo-only button right now.")
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppTheme.primary.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "cart.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppTheme.primary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(cart.title)
                        .font(.headline)
                Text(cart.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                }

                Spacer()
            }

            Divider().opacity(0.25)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Store")
                        .font(.caption).bold()
                        .foregroundStyle(.secondary)
                    Text(cart.storeName)
                        .font(.subheadline)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("ETA")
                        .font(.caption).bold()
                        .foregroundStyle(.secondary)
                    Text(cart.etaText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var checkoutCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Summary")
                    .font(.headline)
                Spacer()
                Text("\(cart.items.count) items")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                MetricPill(systemImage: "bag.fill", text: "\(cart.items.count) items", color: .blue)
                MetricPill(systemImage: "calendar", text: "5 days", color: .orange)
            }

            Button {
                tap("Checkout (Instacart)")
            } label: {
                Label("Checkout", systemImage: "arrow.right.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var itemsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Items")
                .font(.headline)

            VStack(spacing: 10) {
                ForEach(cart.groupedCategories, id: \.category) { group in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(group.category)
                            .font(.subheadline).bold()
                            .foregroundStyle(.secondary)

                        ForEach(group.items) { item in
                            HStack(spacing: 10) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(uiColor: .tertiarySystemFill))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: item.systemImage)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(AppTheme.primary)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.subheadline).bold()
                                    Text(item.detail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                            .padding(12)
                            .background(Color(uiColor: .tertiarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    .padding(12)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Coach notes")
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(cart.notes, id: \.self) { note in
                    AdviceLine(systemImage: "sparkles", color: AppTheme.primary, text: note)
                }
            }
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func tap(_ name: String) {
        lastTapped = name
        showingMockAlert = true
    }
}

private struct MetricPill: View {
    let systemImage: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
            Text(text)
                .font(.caption).bold()
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Color(uiColor: .tertiarySystemFill))
        .clipShape(Capsule())
    }
}

private struct SampleCartItem: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    let category: String
    let systemImage: String
}

private struct SampleCartCategoryGroup {
    let category: String
    let items: [SampleCartItem]
}

private struct SampleCart {
    let title: String
    let subtitle: String
    let storeName: String
    let etaText: String
    let items: [SampleCartItem]
    let notes: [String]

    var groupedCategories: [SampleCartCategoryGroup] {
        let grouped = Dictionary(grouping: items, by: { $0.category })
        let order = ["Protein", "Produce", "Carbs", "Pantry", "Extras"]
        return order.compactMap { category in
            guard let items = grouped[category] else { return nil }
            return SampleCartCategoryGroup(category: category, items: items)
        }
    }
}

#Preview {
    NavigationStack {
        GroceryCartMockView()
    }
}

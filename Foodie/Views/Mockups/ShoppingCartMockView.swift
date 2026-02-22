//
//  ShoppingCartMockView.swift
//  Foodie
//
//  Mock: shopping cart list.
//

import SwiftUI

struct ShoppingCartMockView: View {
    @Environment(\.dismiss) private var dismiss
    private let items: [CartItem] = [
        CartItem(name: "Bananas", detail: "Qty: 4 each", tags: ["Fresh Produce"]),
        CartItem(name: "Apples", detail: "Qty: 4 each", tags: ["Fresh Produce"]),
        CartItem(name: "Eggs", detail: "Qty: 1 dozen", tags: ["Protein"]),
        CartItem(name: "Whole-grain bread", detail: "Qty: 1 loaf", tags: ["Whole Grain"]),
        CartItem(name: "Chicken breast", detail: "Qty: 1.5 lb", tags: ["Protein"])
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                itemsList
                Spacer(minLength: 20)
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Text("Order on Instacart")
                        .font(.title3).bold()
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
        .navigationTitle("Your Shopping Cart")
        .navigationBarTitleDisplayMode(.inline)
        .mockupsFullscreen()
        .navigationBarBackButtonHidden(true)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Your Shopping Cart")
                    .font(.title2).bold()
                Text("5 items ready to order")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var itemsList: some View {
        VStack(spacing: 10) {
            ForEach(items) { item in
                CartRow(item: item)
            }
        }
    }
}

private struct CartItem: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    let tags: [String]
}

private struct CartRow: View {
    let item: CartItem

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(accentColor(for: item).opacity(0.18))
                .frame(width: 6)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.title3).bold()
                Text(item.detail)
                    .font(.body)
                    .foregroundStyle(.secondary)

                if !item.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(item.tags, id: \.self) { tag in
                            TagPill(text: tag)
                        }
                    }
                    .padding(.top, 2)
                }
            }

            Spacer()
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [AppTheme.card, AppTheme.card.opacity(0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func accentColor(for item: CartItem) -> Color {
        if item.tags.contains(where: { $0.lowercased().contains("produce") }) { return .green }
        if item.tags.contains(where: { $0.lowercased().contains("protein") }) { return .purple }
        if item.tags.contains(where: { $0.lowercased().contains("whole") }) { return .orange }
        if item.tags.contains(where: { $0.lowercased().contains("fiber") }) { return .blue }
        if item.tags.contains(where: { $0.lowercased().contains("dairy") }) { return .pink }
        return AppTheme.primary
    }
}

private struct TagPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline).bold()
            .foregroundStyle(color(for: text))
            .padding(.vertical, 5)
            .padding(.horizontal, 9)
            .background(color(for: text).opacity(0.14))
            .clipShape(Capsule())
    }

    private func color(for tag: String) -> Color {
        let lower = tag.lowercased()
        if lower.contains("fresh produce") { return .green }
        if lower.contains("protein") { return .purple }
        if lower.contains("whole grain") { return .orange }
        if lower.contains("fiber") { return .blue }
        if lower.contains("dairy") { return .pink }
        return AppTheme.primary
    }
}

#Preview {
    NavigationStack {
        ShoppingCartMockView()
    }
}

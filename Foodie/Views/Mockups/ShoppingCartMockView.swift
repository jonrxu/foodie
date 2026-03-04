//
//  ShoppingCartMockView.swift
//  Foodie
//
//  Simple survey mock: clear grocery cart + one checkout action.
//

import SwiftUI

struct ShoppingCartMockView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showInstacartCheckout = false

    private let items: [CartItem] = [
        CartItem(name: "Bananas", detail: "4 each", tag: "Produce", color: .green, icon: "🍌"),
        CartItem(name: "Apples", detail: "4 each", tag: "Produce", color: .green, icon: "🍎"),
        CartItem(name: "Eggs", detail: "1 dozen", tag: "Protein", color: .teal, icon: "🥚"),
        CartItem(name: "Whole-grain bread", detail: "1 loaf", tag: "Carbs", color: .orange, icon: "🍞"),
        CartItem(name: "Chicken breast", detail: "1.5 lb", tag: "Protein", color: .teal, icon: "🍗")
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                pageBackground
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                        Spacer(minLength: 16)
                        cartCard
                        Spacer(minLength: 20)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dismiss()
                    }

                    orderButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 62)
                .padding(.bottom, 24)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .mockupsFullscreen()
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showInstacartCheckout) {
            InstacartCheckoutMockView()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your shopping cart")
                .font(.system(size: 36, weight: .bold, design: .rounded))

            Text("Here is your personal shopping list based on your food logs and CGM data this week")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var cartCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Items")
                    .font(.title3.weight(.bold))
                Spacer()
                Label("Customize", systemImage: "square.and.pencil")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.primary.opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(.bottom, 4)
            .padding(.bottom, 6)

            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                CartRow(item: item)
                if index < items.count - 1 {
                    Divider()
                        .padding(.leading, 54)
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

    private var orderButton: some View {
        HStack {
            Spacer()
            Button {
                showInstacartCheckout = true
            } label: {
                Text("Order on Instacart")
                    .font(.title3.weight(.semibold))
                    .padding(.horizontal, 26)
                    .padding(.vertical, 12)
                    .foregroundStyle(.white)
                    .background(AppTheme.primary)
                    .clipShape(Capsule())
            }
            Spacer()
        }
    }

    private var pageBackground: some View {
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
                endRadius: 540
            )
        }
    }
}

private struct CartItem: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    let tag: String
    let color: Color
    let icon: String
}

private struct CartRow: View {
    let item: CartItem

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(item.color.opacity(0.16))
                    .frame(width: 42, height: 42)
                Text(item.icon)
                    .font(.system(size: 22))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.title3.weight(.semibold))
                Text(item.detail)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            TagPill(text: item.tag, color: item.color)
        }
        .padding(.vertical, 12)
    }
}

private struct TagPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.13))
            .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        ShoppingCartMockView()
    }
}

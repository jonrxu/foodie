//
//  PrototypeShoppingCartView.swift
//  Foodie
//

import SwiftUI

struct PrototypeShoppingCartView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var mealFlowViewModel: PrototypeMealFlowViewModel

    let hideTabBar: Bool

    @State private var showInstacartCheckout = false
    @State private var isHandingOffToCheckout = false

    init(hideTabBar: Bool = true) {
        self.hideTabBar = hideTabBar
    }

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
        .modifier(PrototypeTabBarVisibilityModifier(hideTabBar: hideTabBar))
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showInstacartCheckout) {
            InstacartCheckoutMockView()
        }
        .task {
            await mealFlowViewModel.bootstrapIfNeeded()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your shopping cart")
                .font(.system(size: 33, weight: .bold, design: .rounded))

            Text(headerSubtitle)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var cartCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Items")
                    .font(.headline.weight(.semibold))
                Spacer()
                Label("Customize", systemImage: "square.and.pencil")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(AppTheme.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.primary.opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(.bottom, 10)

            ForEach(Array(displayItems.enumerated()), id: \.element.id) { index, item in
                PrototypeCartRow(item: item)
                if index < displayItems.count - 1 {
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

    // Instacart brand colors (dark theme)
    private let instacartGreen = Color(red: 0 / 255, green: 61 / 255, blue: 41 / 255)       // #003D29
    private let instacartCashew = Color(red: 250 / 255, green: 241 / 255, blue: 229 / 255)  // #FAF1E5

    private var orderButton: some View {
        let isLoading = mealFlowViewModel.isPreparingCheckout || isHandingOffToCheckout
        let isDisabled = mealFlowViewModel.activeCartDraft == nil || isLoading

        return HStack {
            Spacer()
            Button {
                Task {
                    guard !isHandingOffToCheckout else { return }
                    await MainActor.run { isHandingOffToCheckout = true }
                    let didPrepare = await mealFlowViewModel.prepareCheckout()
                    if didPrepare {
                        try? await Task.sleep(for: .milliseconds(450))
                        await MainActor.run {
                            if let checkoutURL = mealFlowViewModel.activeCartDraft?.checkoutURL {
                                openURL(checkoutURL)
                            } else {
                                showInstacartCheckout = true
                            }
                        }
                    }
                    await MainActor.run { isHandingOffToCheckout = false }
                }
            } label: {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(instacartCashew)
                            .frame(width: 22, height: 22)
                    } else {
                        Image("instacart-carrot")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                    }
                    Text(isLoading ? "Preparing..." : "Shop ingredients")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(instacartCashew)
                    if !isLoading {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(instacartCashew)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(instacartGreen)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.5 : 1)
            Spacer()
        }
    }

    private var headerSubtitle: String {
        if mealFlowViewModel.activeCartDraft?.source == .mealFeedback {
            return "Here are simple grocery swaps based on your latest meal and CGM pattern"
        }
        return "Here is your personal shopping list based on your food logs and CGM data this week"
    }

    private var displayItems: [PrototypeCartDisplayItem] {
        guard let draft = mealFlowViewModel.activeCartDraft, !draft.items.isEmpty else {
            return [
                PrototypeCartDisplayItem(name: "Bananas", detail: "4 each", tag: "Produce", color: .green, icon: "🍌"),
                PrototypeCartDisplayItem(name: "Apples", detail: "4 each", tag: "Produce", color: .green, icon: "🍎"),
                PrototypeCartDisplayItem(name: "Eggs", detail: "1 dozen", tag: "Protein", color: .teal, icon: "🥚"),
                PrototypeCartDisplayItem(name: "Whole-grain bread", detail: "1 loaf", tag: "Carbs", color: .orange, icon: "🍞"),
                PrototypeCartDisplayItem(name: "Chicken breast", detail: "1.5 lb", tag: "Protein", color: .teal, icon: "🍗")
            ]
        }

        return draft.items.map { item in
            let category = item.category ?? "Suggested"
            return PrototypeCartDisplayItem(
                name: item.name,
                detail: item.quantity ?? "1 item",
                tag: category,
                color: style(for: category).color,
                icon: style(for: category).icon
            )
        }
    }

    private func style(for category: String) -> (icon: String, color: Color) {
        let normalized = category.lowercased()
        if normalized.contains("produce") || normalized.contains("vegetable") {
            return ("🥬", .green)
        }
        if normalized.contains("protein") {
            return ("🍗", .teal)
        }
        if normalized.contains("carb") {
            return ("🍞", .orange)
        }
        if normalized.contains("beverage") {
            return ("🥤", .blue)
        }
        return ("🛒", .indigo)
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

private struct PrototypeCartDisplayItem: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    let tag: String
    let color: Color
    let icon: String
}

private struct PrototypeCartRow: View {
    let item: PrototypeCartDisplayItem

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
                    .font(.headline.weight(.semibold))
                Text(item.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(item.tag)
                .font(.caption.weight(.semibold))
                .foregroundStyle(item.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(item.color.opacity(0.13))
                .clipShape(Capsule())
        }
        .padding(.vertical, 12)
    }
}

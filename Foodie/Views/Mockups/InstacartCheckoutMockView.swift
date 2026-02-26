//
//  InstacartCheckoutMockView.swift
//  Foodie
//
//  Mockup: external Instacart-style cart screen after handoff.
//

import SwiftUI

struct InstacartCheckoutMockView: View {
    @Environment(\.dismiss) private var dismiss

    private let subtotalText = "$30.30"
    private let voucherText = "-$30.30"
    private let totalDueText = "$0.00"

    private let items: [InstacartLineItem] = [
        InstacartLineItem(
            name: "Banana (About 0.42 lb each)",
            price: "$1.15",
            oldPrice: nil,
            quantity: "4 ct",
            icon: "🍌",
            usesTrash: false
        ),
        InstacartLineItem(
            name: "Honeycrisp Apple (About 0.58 lb each)",
            price: "$7.86",
            oldPrice: "$9.26",
            quantity: "4 ct",
            icon: "🍎",
            usesTrash: false
        ),
        InstacartLineItem(
            name: "Store Brand Eggs, Large, Grade A (12 ct)",
            price: "$1.99",
            oldPrice: nil,
            quantity: "1 ct",
            icon: "🥚",
            usesTrash: true
        ),
        InstacartLineItem(
            name: "Arnold Whole Grains, Healthy Bread (24 oz)",
            price: "$5.99",
            oldPrice: nil,
            quantity: "1 ct",
            icon: "🍞",
            usesTrash: true
        ),
        InstacartLineItem(
            name: "Perdue Fresh Boneless Skinless Chicken Breasts",
            price: "$4.94",
            oldPrice: "$8.98",
            quantity: "1.5 lbs",
            icon: "🍗",
            usesTrash: true
        ),
        InstacartLineItem(
            name: "Store Brand Greek Nonfat Plain Yogurt (32 oz)",
            price: "$4.59",
            oldPrice: nil,
            quantity: "1 ct",
            icon: "🥛",
            usesTrash: true
        ),
        InstacartLineItem(
            name: "Broccoli Crown (About 0.82 lb each)",
            price: "$3.78",
            oldPrice: nil,
            quantity: "2 ct",
            icon: "🥦",
            usesTrash: false
        )
    ]

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                topBar
                Divider()

                storeSummary
                Divider()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(items) { item in
                            InstacartItemRow(item: item)
                            Divider()
                                .padding(.leading, 100)
                        }
                    }
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dismiss()
                    }
                }

                footer
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            .background(Color.white)
            .ignoresSafeArea(edges: .bottom)
        }
        .toolbar(.hidden, for: .navigationBar)
        .mockupsFullscreen()
        .navigationBarBackButtonHidden(true)
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.black)
            }
            .buttonStyle(.plain)

            Spacer()

            ZStack {
                Circle()
                    .fill(Color(uiColor: .systemGray6))
                    .frame(width: 46, height: 46)
                    .overlay(
                        Circle()
                            .stroke(Color(uiColor: .systemGray4), lineWidth: 1)
                    )
                Text("GIANT")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.red)
            }

            Spacer()

            Image(systemName: "person.badge.plus")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.black)
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    private var storeSummary: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("GIANT")
                    .font(.system(size: 17, weight: .bold))
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text(totalDueText)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.green.opacity(0.95))
                    Text(subtotalText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .strikethrough()
                }
            }

            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 12, weight: .bold))
                Text("Delivery by 9:26-9:37pm")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(Color.green.opacity(0.95))

            Text("Fresh Funds voucher applied \(voucherText)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.green.opacity(0.95))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Text("$0 delivery fee + saving $5.44 on this order")
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.yellow.opacity(0.65))

            Button {
                dismiss()
            } label: {
                HStack {
                    Spacer()
                    Text("Go to checkout")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(totalDueText)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.green.opacity(0.55))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(Color.green)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .background(Color.white)
        }
    }
}

private struct InstacartLineItem: Identifiable {
    let id = UUID()
    let name: String
    let price: String
    let oldPrice: String?
    let quantity: String
    let icon: String
    let usesTrash: Bool
}

private struct InstacartItemRow: View {
    let item: InstacartLineItem

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(item.icon)
                .font(.system(size: 38))
                .frame(width: 56, height: 56, alignment: .topLeading)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineSpacing(1)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 5) {
                    Text(item.price)
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, item.oldPrice == nil ? 0 : 2)
                        .background(
                            item.oldPrice == nil ? Color.clear : Color.yellow.opacity(0.65)
                        )

                    if let oldPrice = item.oldPrice {
                        Text(oldPrice)
                            .font(.system(size: 12.5, weight: .regular))
                            .foregroundStyle(.secondary)
                            .strikethrough()
                    }
                }

                Text("Add Instructions")
                    .font(.system(size: 12.5, weight: .medium))
                    .underline()
                    .foregroundStyle(.secondary)
            }
            .layoutPriority(1)

            Spacer(minLength: 6)

            QuantityPicker(quantity: item.quantity, usesTrash: item.usesTrash)
                .padding(.top, 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 7)
    }
}

private struct QuantityPicker: View {
    let quantity: String
    let usesTrash: Bool

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: usesTrash ? "trash" : "minus")
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 18)

            Text(quantity)
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.9)

            Image(systemName: "plus")
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 18)
        }
        .padding(.horizontal, 10)
        .frame(width: 136, height: 40)
        .background(Color(uiColor: .systemGray6))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color(uiColor: .systemGray4), lineWidth: 0.7)
        )
    }
}

#Preview {
    NavigationStack {
        InstacartCheckoutMockView()
    }
}

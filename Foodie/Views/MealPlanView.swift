//
//  MealPlanView.swift
//  Foodie
//
//  Created by AI Assistant.
//

import SwiftUI

struct MealPlanView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                placeholderCard(icon: "cart.fill", title: "Weekly Plan", subtitle: "Auto-generate a simple plan")
                placeholderCard(icon: "list.bullet", title: "Grocery List", subtitle: "Organized by aisle")
                placeholderCard(icon: "sparkles", title: "Smart Swaps", subtitle: "Dietary and budget-friendly")
            }
            .padding()
        }
        .background(AppTheme.background)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Meal Planning")
                .font(.title2).bold()
            Text("Keep it simple, tasty, and on budget")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func placeholderCard(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(AppTheme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    NavigationStack { MealPlanView() }
}



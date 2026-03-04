//
//  MockupsView.swift
//  Foodie
//
//  Demo-only mock screens for prototyping.
//

import SwiftUI

struct MockupsView: View {
    var body: some View {
        List {
            Section {
                NavigationLink {
                    ProfileSetupMockView()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("1. Profile setup")
                            .font(.headline)
                        Text("Simple onboarding for preferences")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

                NavigationLink {
                    DinnerMealSelectionMockView()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("2. Pick meal types")
                            .font(.headline)
                        Text("Dinner selected + add meals to cart")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

                NavigationLink {
                    FoodLoggingMockView()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("3. Log a meal")
                            .font(.headline)
                        Text("Voice or photo in one tap")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

                NavigationLink {
                    PlateFeedbackMockView()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("4. Plate feedback")
                            .font(.headline)
                        Text("Predicted spike and AI coaching")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

                NavigationLink {
                    WeeklyGlucoseOverviewMockView()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("5. Weekly CGM overview")
                            .font(.headline)
                        Text("Single weekly trend with target range")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

                NavigationLink {
                    ShoppingCartMockView()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("6. Order groceries")
                            .font(.headline)
                        Text("Large-text cart and one-tap checkout")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

                NavigationLink {
                    InstacartCheckoutMockView()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("7. Instacart checkout")
                            .font(.headline)
                        Text("External handoff screen mock")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }
            } header: {
                Text("Survey Prototype (7 screens)")
            } footer: {
                Text("Show these in order for quick concept feedback.")
            }
        }
        .navigationTitle("Mockups")
        .navigationBarTitleDisplayMode(.inline)
        .mockupsFullscreen()
    }
}

#Preview {
    NavigationStack {
        MockupsView()
    }
}

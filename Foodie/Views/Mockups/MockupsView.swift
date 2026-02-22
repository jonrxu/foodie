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
                    FoodLoggingMockView()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("1. Log a meal")
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
                        Text("2. Plate feedback")
                            .font(.headline)
                        Text("Balanced plate model in plain language")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

                NavigationLink {
                    WeeklyGlucoseOverviewMockView()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("3. Weekly CGM overview")
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
                        Text("4. Order groceries")
                            .font(.headline)
                        Text("Large-text cart and one-tap checkout")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }
            } header: {
                Text("Survey Prototype (4 screens)")
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

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
                    PlateFeedbackMockView()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Step 3 • Plate feedback")
                            .font(.headline)
                        Text("Show macro breakdown and coaching suggestions")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

                NavigationLink {
                    FoodLoggingMockView()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Step 2 • Log food (voice / photo / text)")
                            .font(.headline)
                        Text("Mock multi-modal logging options (visuals only)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

                NavigationLink {
                    GroceryCartMockView()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Grocery cart • Sample generated cart")
                            .font(.headline)
                        Text("Mock cart with items, prices, and checkout CTAs")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }
            } header: {
                Text("Food logging demo flow")
            }

            Section {
                NavigationLink {
                    WeeklyGlucoseOverviewMockView()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CGM • Weekly overview (Slide 2)")
                            .font(.headline)
                        Text("Time in range + key stats + weekly pattern")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

                NavigationLink {
                    FoodRecommendationsMockView()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CGM • Food recommendations (Slide 3)")
                            .font(.headline)
                        Text("Suggested foods + “Add to cart” actions")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }
            } header: {
                Text("CGM demo flow (slides 2–3)")
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



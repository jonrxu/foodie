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
                    PatientOnboardingStepOneView()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("About you (Step 1)")
                            .font(.headline)
                        Text("Diet, low sodium, dislikes, activity level")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

                NavigationLink {
                    MealPreferenceMockView()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Meal preferences (Step 2)")
                            .font(.headline)
                        Text("Select focus areas + meal types")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

                NavigationLink {
                    ShoppingCartMockView()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Shopping cart (Step 3)")
                            .font(.headline)
                        Text("Tagged items + order button")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }
            } header: {
                Text("Mockup 1 • Onboarding → Cart")
            }

            Section {
                NavigationLink {
                    FoodLoggingMockView()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Log a meal (Step 1)")
                            .font(.headline)
                        Text("Voice, photo, text, or barcode")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

                NavigationLink {
                    PlateFeedbackMockView()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Plate feedback (Step 2)")
                            .font(.headline)
                        Text("Balanced plate ring + simple tips")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

                NavigationLink {
                    GroceryCartMockView()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Grocery cart (Step 3)")
                            .font(.headline)
                        Text("Generated cart + checkout")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }
            } header: {
                Text("Mockup 2 • Food logging")
            }

            Section {
                NavigationLink {
                    NighttimeGlucoseMockView()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CGM • Nighttime summary (Step 2)")
                            .font(.headline)
                        Text("Nights above range + avg nighttime glucose (last 7 days)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

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

//
//  SimpleOnboardingView.swift
//  Foodie
//
//

import SwiftUI

struct SimpleOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var session: AppSession
    
    @State private var name: String = ""
    @State private var dietaryNotes: String = ""
    @State private var allergyNotes: String = ""
    @State private var currentStep = 0
    
    private let steps = ["Welcome", "Basics", "Preferences"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar
                
                TabView(selection: $currentStep) {
                    welcomeStep
                        .tag(0)
                    
                    basicsStep
                        .tag(1)
                    
                    preferencesStep
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .background(AppTheme.background)
        }
    }
    
    private var progressBar: some View {
        VStack(spacing: 8) {
            HStack {
                Text(steps[currentStep])
                    .font(.title2).bold()
                Spacer()
                Text("Step \(currentStep + 1) of \(steps.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            ProgressView(value: Double(currentStep + 1), total: Double(steps.count))
                .accentColor(AppTheme.primary)
        }
        .padding()
    }
    
    private var welcomeStep: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "sparkles")
                .font(.system(size: 80))
                .foregroundStyle(AppTheme.primary)
            
            VStack(spacing: 12) {
                Text("Welcome to Foodie")
                    .font(.title).bold()
                
                Text("Your voice-first food & grocery companion")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 40)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "mic.fill", title: "Voice Food Logging", description: "Talk to log meals in seconds")
                FeatureRow(icon: "cart.fill", title: "Smart Groceries", description: "AI generates your weekly cart")
                FeatureRow(icon: "bell.fill", title: "Gentle Reminders", description: "Never forget to log or shop")
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            Button {
                withAnimation {
                    currentStep = 1
                }
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
    
    private var basicsStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What should we call you?")
                        .font(.headline)
                    
                    TextField("Your name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 8)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Any dietary restrictions? (Optional)")
                        .font(.headline)
                    
                    Text("E.g., vegetarian, vegan, pescatarian, keto, etc.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextField("Dietary preferences", text: $dietaryNotes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .frame(minHeight: 80)
                        .padding(.horizontal, 8)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Any allergies to avoid? (Optional)")
                        .font(.headline)
                    
                    Text("E.g., nuts, dairy, shellfish, gluten, etc.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextField("Allergies", text: $allergyNotes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .frame(minHeight: 80)
                        .padding(.horizontal, 8)
                }
                
                Spacer(minLength: 100)
            }
            .padding(24)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                Button {
                    withAnimation {
                        currentStep = 2
                    }
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppTheme.primary.opacity(0.3) : AppTheme.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                
                Button("Back") {
                    withAnimation {
                        currentStep = 0
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            .background(.ultraThinMaterial)
        }
    }
    
    private var preferencesStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("You're all set!")
                        .font(.title2).bold()
                    
                    Text("Foodie will help you:")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                
                VStack(spacing: 16) {
                    InfoCard(
                        icon: "mic.fill",
                        title: "Log meals daily",
                        description: "We'll remind you at 8 PM to quickly log what you ate"
                    )
                    
                    InfoCard(
                        icon: "cart.fill",
                        title: "Order groceries weekly",
                        description: "Every Sunday at 10 AM, we'll generate a smart grocery list"
                    )
                    
                    InfoCard(
                        icon: "sparkles",
                        title: "Learn your patterns",
                        description: "The more you log, the smarter your grocery suggestions become"
                    )
                }
                
                Spacer(minLength: 100)
            }
            .padding(24)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                Button {
                    completeOnboarding()
                } label: {
                    Text("Start Using Foodie")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                Button("Back") {
                    withAnimation {
                        currentStep = 1
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            .background(.ultraThinMaterial)
        }
    }
    
    private func completeOnboarding() {
        // Save profile
        var profile = UserProfile()
        profile.displayName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.customDietaryNotes = dietaryNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.customAllergyNotes = allergyNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.hasCompletedOnboarding = true
        profile.joinedDate = Date()
        
        session.updateProfile { $0 = profile }
        session.completeOnboarding()
        
        // Setup notifications
        Task {
            await NotificationService.shared.setupNotifications()
        }
        
        dismiss()
    }
}

// MARK: - Supporting Views

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(AppTheme.primary)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline).bold()
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

private struct InfoCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(AppTheme.primary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    SimpleOnboardingView()
        .environmentObject(AppSession.shared)
}


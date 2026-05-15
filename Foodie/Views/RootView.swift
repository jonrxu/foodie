//
//  RootView.swift
//  Foodie
//

import SwiftUI

@MainActor
final class AuthViewModel: ObservableObject {
    static let shared = AuthViewModel()

    @Published private(set) var currentSession: AuthSession?
    @Published private(set) var isBootstrapping = false
    @Published private(set) var isSubmitting = false
    @Published private(set) var infoMessage: String?
    @Published private(set) var errorMessage: String?

    private let authClient: SupabaseAuthClient
    private let backendClient: BackendClient
    private let appSession: AppSession
    private var didBootstrap = false

    init(
        authClient: SupabaseAuthClient = .shared,
        backendClient: BackendClient = .shared,
        appSession: AppSession = .shared
    ) {
        self.authClient = authClient
        self.backendClient = backendClient
        self.appSession = appSession
    }

    var isAuthenticated: Bool {
        currentSession != nil
    }

    func bootstrapIfNeeded() async {
        guard !didBootstrap else { return }
        didBootstrap = true
        await restoreSession()
    }

    func restoreSession() async {
        isBootstrapping = true
        defer { isBootstrapping = false }

        do {
            if let restored = try await authClient.restoreSession() {
                currentSession = restored
                await syncBackendProfile()
            } else {
                currentSession = nil
            }
            errorMessage = nil
        } catch {
            currentSession = nil
            AuthSessionStore.shared.clear()
            errorMessage = error.localizedDescription
        }
    }

    func signIn(email: String, password: String) async -> Bool {
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            currentSession = try await authClient.signIn(email: email, password: password)
            infoMessage = nil
            errorMessage = nil
            await syncBackendProfile()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func signUp(name: String, email: String, password: String) async -> Bool {
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let result = try await authClient.signUp(name: name, email: email, password: password)
            switch result {
            case .authenticated(let session):
                currentSession = session
                infoMessage = nil
                errorMessage = nil
                try await updateBackendProfile(
                    displayName: name,
                    dietPreferences: [],
                    careGoals: [],
                    supportPreferences: [],
                    hasCompletedOnboarding: false
                )
                return true
            case .emailVerificationRequired:
                currentSession = nil
                errorMessage = nil
                infoMessage = "Check your email to verify your account, then sign in."
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func completeOnboarding(
        displayName: String,
        dietPreferences: [String],
        careGoals: [String],
        supportPreferences: [String]
    ) async -> Bool {
        do {
            try await updateBackendProfile(
                displayName: displayName,
                dietPreferences: dietPreferences,
                careGoals: careGoals,
                supportPreferences: supportPreferences,
                hasCompletedOnboarding: true
            )
            appSession.completeOnboarding()
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func signOut() async {
        await authClient.signOut()
        currentSession = nil
        infoMessage = nil
        errorMessage = nil
        appSession.signOut()
    }

    func clearMessages() {
        infoMessage = nil
        errorMessage = nil
    }

    private func syncBackendProfile() async {
        do {
            let profile = try await backendClient.fetchCurrentUserProfile()
            appSession.syncFromBackend(
                displayName: profile.displayName,
                email: profile.email,
                hasCompletedOnboarding: profile.hasCompletedOnboarding
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func updateBackendProfile(
        displayName: String,
        dietPreferences: [String],
        careGoals: [String],
        supportPreferences: [String],
        hasCompletedOnboarding: Bool
    ) async throws {
        let profile = try await backendClient.updateCurrentUserProfile(
            displayName: displayName,
            dietPreferences: dietPreferences,
            careGoals: careGoals,
            supportPreferences: supportPreferences,
            hasCompletedOnboarding: hasCompletedOnboarding
        )
        appSession.syncFromBackend(
            displayName: profile.displayName,
            email: profile.email,
            hasCompletedOnboarding: profile.hasCompletedOnboarding
        )
    }
}

struct RootView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var dexcomViewModel: DexcomConnectionViewModel
    @EnvironmentObject private var agentFeedViewModel: AgentFeedViewModel
    @EnvironmentObject private var mealFlowViewModel: PrototypeMealFlowViewModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if authViewModel.isBootstrapping {
                ProgressView("Loading Foodie")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
            } else if authViewModel.isAuthenticated {
                PrototypeAppShellView()
            } else {
                AuthenticationView()
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { isAuthenticated in
            guard isAuthenticated else { return }
            Task {
                await dexcomViewModel.bootstrapIfNeeded()
                await mealFlowViewModel.bootstrapIfNeeded()
                await agentFeedViewModel.bootstrapIfNeeded()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            guard newPhase == .active else { return }
            Task {
                await authViewModel.restoreSession()
                if authViewModel.isAuthenticated {
                    await dexcomViewModel.refreshConnectionStatus()
                    await mealFlowViewModel.bootstrapIfNeeded()
                    await agentFeedViewModel.refresh()
                }
            }
        }
    }
}

private struct AuthenticationView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    @State private var isCreatingAccount = false
    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        GeometryReader { geo in
            ZStack {
                PrototypePageBackground()
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(isCreatingAccount ? "Create your account" : "Sign in")
                            .font(.system(size: 33, weight: .bold, design: .rounded))
                        Text(isCreatingAccount ? "Secure your Foodie account before onboarding" : "Use your email and password to continue")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 18)

                    VStack(alignment: .leading, spacing: 14) {
                        if isCreatingAccount {
                            authField(title: "Name", text: $displayName, keyboardType: .default, isSecure: false)
                        }
                        authField(title: "Email", text: $email, keyboardType: .emailAddress, isSecure: false)
                        authField(title: "Password", text: $password, keyboardType: .default, isSecure: true)

                        if let infoMessage = authViewModel.infoMessage, infoMessage.isEmpty == false {
                            Text(infoMessage)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.primary)
                        }

                        if let errorMessage = authViewModel.errorMessage, errorMessage.isEmpty == false {
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundStyle(.red)
                        }

                        Button {
                            Task {
                                if isCreatingAccount {
                                    _ = await authViewModel.signUp(
                                        name: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
                                        email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                                        password: password
                                    )
                                } else {
                                    _ = await authViewModel.signIn(
                                        email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                                        password: password
                                    )
                                }
                            }
                        } label: {
                            Text(primaryButtonTitle)
                                .font(.headline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppTheme.primary)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .disabled(authViewModel.isSubmitting || !canSubmit)
                        .opacity(authViewModel.isSubmitting || !canSubmit ? 0.6 : 1)

                        Button {
                            isCreatingAccount.toggle()
                            authViewModel.clearMessages()
                        } label: {
                            Text(isCreatingAccount ? "Already have an account? Sign in" : "Need an account? Create one")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.primary)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(18)
                    .background(.white.opacity(0.96))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(AppTheme.primary.opacity(0.12), lineWidth: 1)
                    )

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 72)
                .padding(.bottom, 24)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var canSubmit: Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if isCreatingAccount {
            return !trimmedName.isEmpty && trimmedEmail.contains("@") && password.count >= 8
        }
        return trimmedEmail.contains("@") && !password.isEmpty
    }

    private var primaryButtonTitle: String {
        if authViewModel.isSubmitting {
            return isCreatingAccount ? "Creating account..." : "Signing in..."
        }
        return isCreatingAccount ? "Create account" : "Sign in"
    }

    private func authField(
        title: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType,
        isSecure: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Group {
                if isSecure {
                    SecureField(title, text: text)
                } else {
                    TextField(title, text: text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(keyboardType)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color(uiColor: .tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

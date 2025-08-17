//
//  CoachView.swift
//  Foodie
//
//  Created by AI Assistant.
//

import SwiftUI

struct CoachView: View {
    @StateObject private var vm = CoachViewModel()
    @State private var showingApiKeySheet = false

    var body: some View {
        VStack(spacing: 0) {
            header
            quickChips
            Divider()
                .opacity(0.1)
            chatList
            inputBar
        }
        .background(
            LinearGradient(colors: [Color.teal.opacity(0.15), Color.indigo.opacity(0.15)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
        )
        .onAppear { vm.onAppear() }
        .sheet(isPresented: $showingApiKeySheet) { ApiKeySheet() }
        .alert("Error", isPresented: Binding(get: { vm.lastError != nil }, set: { _ in vm.lastError = nil })) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(vm.lastError ?? "Unknown error")
        }
    }

    private var header: some View {
        ZStack {
            LinearGradient(colors: [Color.teal, Color.indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(height: 140)
                .overlay(alignment: .topTrailing) {
                    HStack(spacing: 10) {
                        streakBadge
                        Button {
                            showingApiKeySheet = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.top, 40)
                    .padding(.trailing, 16)
                }

            HStack(spacing: 12) {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(.white)
                Text("Foodie Coach")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }

    private var streakBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill").foregroundStyle(.orange)
            Text("\(vm.streakCount)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color.white.opacity(0.15))
        .clipShape(Capsule())
        .accessibilityLabel("Streak \(vm.streakCount) days")
    }

    private var quickChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(vm.quickPrompts, id: \.self) { text in
                    Button {
                        vm.applyQuickPrompt(text)
                    } label: {
                        HStack(spacing: 6) {
                            Text(text)
                                .font(.system(size: 14, weight: .semibold))
                            Image(systemName: "sparkles")
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }

    private var chatList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(vm.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                }
            }
            .onChange(of: vm.messages.count) { _ in
                if let last = vm.messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
            }
        }
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("What’s your goal today?", text: $vm.inputText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)
                .disabled(vm.isStreaming)

            Button(action: vm.sendCurrentInput) {
                Image(systemName: vm.isStreaming ? "hourglass" : "paperplane.fill")
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(vm.isStreaming ? Color.gray : Color.blue)
                    .clipShape(Circle())
            }
            .disabled(vm.isStreaming)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.thinMaterial)
    }
}

private struct ApiKeySheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var key: String = ApiKeyStore.shared.getApiKey() ?? ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("OpenAI API Key")) {
                    SecureField("sk-...", text: $key)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        ApiKeyStore.shared.saveApiKey(key)
                        dismiss()
                    }
                    .disabled(key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    CoachView()
}



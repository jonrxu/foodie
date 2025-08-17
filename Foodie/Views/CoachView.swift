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
    @State private var showingSessions = false
    @State private var showingClearConfirm = false

    var body: some View {
        ZStack {
            // Background gradient with playful green vibes
            LinearGradient(colors: [Color.green.opacity(0.18), Color.teal.opacity(0.12)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 0) {
            header
            quickChips
            Divider()
                .opacity(0.1)
            chatList
            inputBar
            }
        }
        .onAppear { vm.onAppear() }
        .sheet(isPresented: $showingApiKeySheet) { ApiKeySheet() }
        .sheet(isPresented: $showingSessions) { SessionsSheet(vm: vm) }
        .alert("Error", isPresented: Binding(get: { vm.lastError != nil }, set: { _ in vm.lastError = nil })) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(vm.lastError ?? "Unknown error")
        }
        .alert("Clear chat?", isPresented: $showingClearConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) { vm.clearCurrentChat() }
        } message: {
            Text("This will remove messages in the current chat.")
        }
        .overlay(alignment: .top) {
            if vm.showConfetti { ConfettiView().allowsHitTesting(false) }
        }
    }

    private var header: some View {
        ZStack {
            LinearGradient(colors: [Color.green, Color.teal], startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(height: 140)
                .overlay(alignment: .topTrailing) {
                    HStack(spacing: 10) {
                        streakBadge
                        Button {
                            showingSessions = true
                        } label: {
                            Image(systemName: "text.justify")
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                                .accessibilityLabel("Chats")
                        }
                        Button {
                            showingClearConfirm = true
                        } label: {
                            Image(systemName: "trash.fill")
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                                .accessibilityLabel("Clear chat")
                        }
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
                    .padding(.top, 18)
                    .padding(.trailing, 16)
                }

            HStack(spacing: 12) {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(.white)
                Text("Foodie Coach")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.top, 12)
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
            .onChange(of: vm.messages.count) { old, new in
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

            if vm.isStreaming {
                Button(action: { vm.cancelStreaming() }) {
                    Image(systemName: "stop.fill")
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(Color.red)
                        .clipShape(Circle())
                        .accessibilityLabel("Stop response")
                }
            } else {
                Button(action: vm.sendCurrentInput) {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                .disabled(vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.thinMaterial)
    }
}

private struct ConfettiView: View {
    @State private var animate = false

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let colors: [Color] = [.green, .mint, .teal, .yellow, .orange]
                let particles = 60
                let time = timeline.date.timeIntervalSinceReferenceDate
                for i in 0..<particles {
                    let progress = (Double(i) / Double(particles))
                    var x = Double.random(in: 0...Double(size.width))
                    var y = (time * 120 + Double(i) * 8).truncatingRemainder(dividingBy: Double(size.height + 100)) - 100
                    var transform = CGAffineTransform(translationX: x, y: y)
                    let rect = CGRect(x: -3, y: -6, width: 6, height: 12)
                    var path = Path(roundedRect: rect, cornerRadius: 2)
                    let rotation = CGFloat((time + Double(i)) .truncatingRemainder(dividingBy: 2)) * .pi
                    transform = transform.rotated(by: rotation)
                    path = path.applying(transform)
                    context.fill(path, with: .color(colors[i % colors.count].opacity(0.9)))
                }
            }
            .frame(height: 180)
        }
    }
}

private struct SessionsSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var vm: CoachViewModel

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Chats")) {
                    ForEach(vm.sessions) { session in
                        Button {
                            vm.loadSession(session)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.title.isEmpty ? "Chat" : session.title)
                                    .font(.headline)
                                Text(session.updatedAt, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Your Chats")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("New Chat") { vm.startNewSession(); dismiss() }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
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



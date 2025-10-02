//
//  CoachView.swift
//  Foodie
//
//  Created by AI Assistant.
//

import SwiftUI

struct CoachView: View {
    @StateObject private var vm = CoachViewModel()
    @State private var showingSessions = false
    @FocusState private var isInputFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                quickChips
                Divider().opacity(0.06)
                chatList
                inputBar
            }
        }
        .onAppear { vm.onAppear() }
        .sheet(isPresented: $showingSessions) { SessionsSheet(vm: vm) }
        .alert("Error", isPresented: Binding(get: { vm.lastError != nil }, set: { _ in vm.lastError = nil })) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(vm.lastError ?? "Unknown error")
        }
        .overlay(alignment: .top) { if vm.showConfetti { ConfettiView().allowsHitTesting(false) } }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showingSessions = true
                } label: {
                    Label("Chats", systemImage: "text.justify")
                        .labelStyle(.titleAndIcon)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    vm.startNewSession()
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("New chat")
            }
        }
        .background(AppTheme.background)
    }

    // Removed heavy header; actions moved to toolbar for a cleaner, minimalist look

    private var quickChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(vm.quickPrompts, id: \.self) { text in
                    Button {
                        vm.applyQuickPrompt(text)
                        isInputFocused = true
                    } label: {
                        HStack(spacing: 6) {
                            Text(text)
                                .foregroundStyle(.primary)
                                .font(.system(size: 14, weight: .semibold))
                            Image(systemName: "sparkles")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color(uiColor: .secondarySystemBackground))
                                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.06), radius: 12, y: 6)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color(uiColor: .separator), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
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
                .padding(.bottom, 4)
            }
            .applyInteractiveKeyboardDismiss()
            .contentShape(Rectangle())
            .onTapGesture { isInputFocused = false }
            .onChange(of: vm.messages.count) { old, new in
                if let last = vm.messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
            }
        }
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 12) {
            TextField("Send a message", text: $vm.inputText, axis: .vertical)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemBackground))
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.28 : 0.1), radius: 12, y: 6)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color(uiColor: .separator), lineWidth: 0.8)
                )
                .lineLimit(1...4)
                .disabled(vm.isStreaming)
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit {
                    isInputFocused = false
                    vm.sendCurrentInput()
                }

            if vm.isStreaming {
                Button(action: { vm.cancelStreaming() }) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(14)
                        .background(
                            Circle()
                                .fill(Color.red.gradient)
                        )
                        .shadow(color: Color.red.opacity(0.2), radius: 14, y: 8)
                        .accessibilityLabel("Stop response")
                }
            } else {
                Button {
                    isInputFocused = false
                    vm.sendCurrentInput()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(14)
                        .background(
                            Circle()
                                .fill(LinearGradient(colors: [AppTheme.primary, AppTheme.primary.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        )
                        .shadow(color: AppTheme.primary.opacity(0.35), radius: 16, y: 10)
                }
                .disabled(vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 18)
        .background(
            VStack(spacing: 0) {
                Color.clear.frame(height: 0)
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
        )
        .overlay(alignment: .top) {
            Divider()
                .background(Color.white.opacity(0.4))
                .blendMode(.overlay)
        }
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
                        .swipeActions {
                            Button(role: .destructive) {
                                vm.deleteSession(session)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Your Chats")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        vm.startNewSession()
                        dismiss()
                    } label: {
                        Label("New Chat", systemImage: "plus")
                    }
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

private extension View {
    @ViewBuilder
    func applyInteractiveKeyboardDismiss() -> some View {
        #if os(iOS)
        if #available(iOS 16.0, *) {
            self.scrollDismissesKeyboard(.interactively)
        } else {
            self
        }
        #else
        self
        #endif
    }
}

#Preview {
    CoachView()
}

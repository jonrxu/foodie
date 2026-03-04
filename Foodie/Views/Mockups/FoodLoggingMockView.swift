//
//  FoodLoggingMockView.swift
//  Foodie
//
//  Simple survey mock: centered photo/voice widgets.
//

import SwiftUI

struct FoodLoggingMockView: View {
    @Environment(\.dismiss) private var dismiss

    private let modes: [LoggingMode] = [
        LoggingMode(title: "Take Photo", systemImage: "camera.fill", tint: Color(red: 0.14, green: 0.53, blue: 0.96)),
        LoggingMode(title: "Voice Log", systemImage: "mic.fill", tint: Color(red: 0.05, green: 0.66, blue: 0.62)),
        LoggingMode(title: "Barcode Scan", systemImage: "barcode.viewfinder", tint: Color(red: 0.95, green: 0.61, blue: 0.16)),
        LoggingMode(title: "Text Log", systemImage: "text.bubble.fill", tint: Color(red: 0.91, green: 0.37, blue: 0.44))
    ]

    var body: some View {
        VStack(spacing: 0) {
            header

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14)
                ],
                spacing: 14
            ) {
                ForEach(modes, id: \.title) { mode in
                    LoggingModeCard(
                        title: mode.title,
                        systemImage: mode.systemImage,
                        tint: mode.tint,
                        action: dismissCurrentScreen
                    )
                }
            }
            .frame(maxWidth: 370)
            .frame(maxWidth: .infinity)
            .padding(.top, 34)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 124)
        .padding(.bottom, 24)
        .background(pageBackground)
        .toolbar(.hidden, for: .navigationBar)
        .mockupsFullscreen()
        .navigationBarBackButtonHidden(true)
        .contentShape(Rectangle())
        .onTapGesture {
            dismiss()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Log your food")
                .font(.system(size: 33, weight: .bold, design: .rounded))
            Text("Chose one simple way to add a meal, snack, or drink")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var pageBackground: some View {
        LinearGradient(
            colors: [
                .white,
                .white,
                AppTheme.primary.opacity(0.004),
                AppTheme.primary.opacity(0.014)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(
            RadialGradient(
                colors: [AppTheme.primary.opacity(0.012), .clear],
                center: UnitPoint(x: 0.5, y: 0.92),
                startRadius: 20,
                endRadius: 360
            )
        )
        .ignoresSafeArea()
    }

    private func dismissCurrentScreen() {
        dismiss()
    }
}

private struct LoggingMode {
    let title: String
    let systemImage: String
    let tint: Color
}

private struct LoggingModeCard: View {
    let title: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(tint.opacity(0.16))
                        .frame(width: 72, height: 72)
                    Image(systemName: systemImage)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(tint)
                }

                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 168)
            .background(
                LinearGradient(
                    colors: [.white, tint.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(tint.opacity(0.26), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(ScaleOnPressStyle())
    }
}

private struct ScaleOnPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    NavigationStack {
        FoodLoggingMockView()
    }
}

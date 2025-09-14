//
//  FoodLogView.swift
//  Foodie
//
//  Created by AI Assistant.
//

import SwiftUI

struct FoodLogView: View {
    var body: some View {
        VStack(spacing: 16) {
            header
            captureRow
            gallery
            Spacer()
        }
        .padding()
        .background(AppTheme.background)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Food Log")
                .font(.title2).bold()
            Text("Snap meals, I’ll estimate nutrition")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var captureRow: some View {
        HStack(spacing: 12) {
            Button {
                // TODO: camera integration
            } label: {
                Label("Capture", systemImage: "camera.fill")
                    .font(.headline)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(AppTheme.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            Button {
                // TODO: import photo
            } label: {
                Label("Import", systemImage: "photo.fill.on.rectangle.fill")
                    .font(.headline)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(AppTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            Spacer()
        }
    }

    private var gallery: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent")
                .font(.headline)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppTheme.card)
                .frame(height: 160)
                .overlay {
                    VStack(spacing: 6) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 28))
                            .foregroundStyle(.secondary)
                        Text("Your meal photos will appear here")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
        }
    }
}

#Preview {
    NavigationStack { FoodLogView() }
}



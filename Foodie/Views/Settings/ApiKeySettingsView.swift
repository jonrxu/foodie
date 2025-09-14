//
//  ApiKeySettingsView.swift
//  Foodie
//
//  Created by AI Assistant.
//

import SwiftUI

struct ApiKeySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var key: String = ApiKeyStore.shared.getApiKey() ?? ""

    var body: some View {
        Form {
            Section(header: Text("OpenAI API Key")) {
                SecureField("sk-...", text: $key)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                Text("Your key is stored locally on this device.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("API Key")
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

#Preview {
    NavigationStack { ApiKeySettingsView() }
}



//
//  ApiKeySettingsView.swift
//  Foodie
//
//

import SwiftUI

struct ApiKeySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var openAIKey: String = ApiKeyStore.shared.getApiKey() ?? ""
    @State private var instacartKey: String = UserPreferencesStore.shared.loadInstacartApiKey() ?? ""

    var body: some View {
        Form {
            Section(header: Text("OpenAI API Key")) {
                SecureField("sk-...", text: $openAIKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                Text("Used for AI meal and list generation. Stored locally.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section(header: Text("Instacart API Key")) {
                SecureField("ic-...", text: $instacartKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                Text("Required to create Instacart shopping lists via MCP.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("API Keys")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    ApiKeyStore.shared.saveApiKey(openAIKey)
                    UserPreferencesStore.shared.saveInstacartApiKey(instacartKey)
                    dismiss()
                }
                .disabled(openAIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}

#Preview {
    NavigationStack { ApiKeySettingsView() }
}



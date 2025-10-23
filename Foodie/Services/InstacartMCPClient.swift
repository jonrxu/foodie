//
//  InstacartMCPClient.swift
//  Foodie
//
//

import Foundation

struct InstacartMCPClient {
    struct Configuration {
        let environment: Environment
        let apiKey: String

        enum Environment {
            case development
            case production

            var baseURL: URL {
                switch self {
                case .development:
                    return URL(string: "https://mcp.dev.instacart.tools/mcp")!
                case .production:
                    return URL(string: "https://mcp.instacart.com/mcp")!
                }
            }
        }
    }

    struct ShoppingListRequestItem: Codable {
        let name: String
        let quantity: String?
        let note: String?
        let store: String?
    }

    struct ShoppingListResponse: Codable {
        let listID: String
        let shareURL: URL
        let itemCount: Int
        let storeName: String?
    }

    private let configuration: Configuration
    private let urlSession: URLSession

    init(configuration: Configuration,
         urlSession: URLSession = .shared) {
        self.configuration = configuration
        self.urlSession = urlSession
    }

    func createShoppingList(items: [ShoppingListRequestItem], title: String?) async throws -> ShoppingListResponse {
        var request = URLRequest(url: configuration.environment.baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")

        struct ToolInvocation: Codable {
            struct Parameters: Codable {
                let title: String?
                let items: [ShoppingListRequestItem]
            }
            let tool: String
            let parameters: Parameters
        }

        let payload = ToolInvocation(tool: "create-shopping-list",
                                     parameters: .init(title: title, items: items))
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await urlSession.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        struct RawResponse: Codable {
            let result: ShoppingListResponse
        }

        return try JSONDecoder().decode(RawResponse.self, from: data).result
    }
}

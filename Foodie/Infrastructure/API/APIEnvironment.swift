//
//  APIEnvironment.swift
//  Foodie
//

import Foundation

struct APIEnvironment {
    enum Mode {
        case stub
        case remote(URL)
    }

    let mode: Mode

    static let stub = APIEnvironment(mode: .stub)
}

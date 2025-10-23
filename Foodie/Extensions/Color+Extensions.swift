//
//  Color+Extensions.swift
//  Foodie
//
//

import SwiftUI

extension Color {
    func darker(by percentage: CGFloat = 0.2) -> Color {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)

        return Color(red: max(r - percentage, 0),
                     green: max(g - percentage, 0),
                     blue: max(b - percentage, 0),
                     opacity: a)
    }
}



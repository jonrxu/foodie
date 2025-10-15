//
//  FlowHelperViews.swift
//  Foodie
//
//  Created by AI Assistant.
//

import SwiftUI

struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let content: (Data.Element) -> Content

    @State private var totalHeight: CGFloat = 0

    init(_ data: Data, spacing: CGFloat = 8, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { geometry in
                self.generateContent(in: geometry)
            }
        }
        .frame(height: totalHeight)
    }

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width: CGFloat = 0
        var height: CGFloat = 0
        var rowHeight: CGFloat = 0

        return ZStack(alignment: .topLeading) {
            ForEach(Array(data.enumerated()), id: \.element) { index, element in
                content(element)
                    .padding(.trailing, spacing)
                    .padding(.bottom, spacing)
                    .alignmentGuide(.leading) { dimension in
                        if width + dimension.width > geometry.size.width {
                            width = 0
                            height += rowHeight + spacing
                            rowHeight = 0
                        }
                        let result = width
                        if width == 0 {
                            rowHeight = dimension.height
                        } else {
                            rowHeight = max(rowHeight, dimension.height)
                        }
                        width += dimension.width + spacing
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if index == data.count - 1 {
                            DispatchQueue.main.async {
                                totalHeight = height + rowHeight + spacing
                            }
                        }
                        return result
                    }
            }
        }
    }
}


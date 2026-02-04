//
//  PatientOnboardingStepOneView.swift
//  Foodie
//
//  First onboarding screen for patient profile details.
//

import SwiftUI

struct PatientOnboardingStepOneView: View {
    @State private var selectedDiets: Set<String> = ["No red meat"]
    @State private var lowSodium: Bool = false
    @State private var dislikes: String = ""
    @State private var activityLevel: ActivityLevel = .lightlyActive

    private let dietOptions = ["Vegan", "Vegetarian", "Pescatarian", "No red meat", "No pork", "Kosher"]

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("WellCart’s food suggestions are designed to be diabetic-friendly and heart healthy.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    dietSection
                    lowSodiumSection
                    dislikesSection
                    activitySection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }

            footer
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Tell us about yourself")
                    .font(.headline)
                Spacer()
                Text("Step 1 of 3")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: 1, total: 3)
                .tint(AppTheme.primary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background(Color(uiColor: .systemBackground))
    }

    private var dietSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Do you follow a specific diet?")
                .font(.subheadline).bold()

            ChipFlowLayout(spacing: 10) {
                ForEach(dietOptions, id: \.self) { option in
                    ChipButton(
                        title: option,
                        isSelected: selectedDiets.contains(option)
                    ) {
                        if selectedDiets.contains(option) {
                            selectedDiets.remove(option)
                        } else {
                            selectedDiets.insert(option)
                        }
                    }
                }
            }
        }
    }

    private var lowSodiumSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Do you follow a low-sodium diet?")
                .font(.subheadline).bold()

            HStack(spacing: 12) {
                ChipButton(title: "Yes", isSelected: lowSodium) {
                    lowSodium = true
                }
                ChipButton(title: "No", isSelected: !lowSodium) {
                    lowSodium = false
                }
            }
        }
    }

    private var dislikesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Are there any fruits and vegetables you absolutely dislike?")
                .font(.subheadline).bold()

            TextField("Enter here", text: $dislikes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .frame(minHeight: 44)
        }
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How would you describe your activity level in a typical week?")
                .font(.subheadline).bold()

            VStack(alignment: .leading, spacing: 10) {
                ForEach(ActivityLevel.allCases, id: \.self) { level in
                    RadioRow(
                        title: level.title,
                        isSelected: activityLevel == level
                    ) {
                        activityLevel = level
                    }
                }
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Button {
                // Continue action for flow integration
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Button("Back") {
                // Back action for flow integration
            }
            .font(.subheadline).bold()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color(uiColor: .systemBackground))
    }
}

private enum ActivityLevel: CaseIterable {
    case notVeryActive
    case lightlyActive
    case active
    case veryActive

    var title: String {
        switch self {
        case .notVeryActive: return "Not very active"
        case .lightlyActive: return "Lightly active"
        case .active: return "Active"
        case .veryActive: return "Very active"
        }
    }
}

private struct ChipButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(isSelected ? .white : .secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(isSelected ? AppTheme.primary : Color(uiColor: .tertiarySystemFill))
                )
        }
        .buttonStyle(.plain)
    }
}

private struct RadioRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? AppTheme.primary : .secondary)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

private struct ChipFlowLayout<Content: View>: View {
    let spacing: CGFloat
    let content: Content

    init(spacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        FlowLayoutContainer(spacing: spacing) {
            content
        }
    }
}

private struct FlowLayoutContainer: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > width, rowWidth > 0 {
                totalHeight += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        totalHeight += rowHeight
        return CGSize(width: width, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }

            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: size.width, height: size.height))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    NavigationStack {
        PatientOnboardingStepOneView()
    }
}

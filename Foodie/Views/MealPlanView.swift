//
//  MealPlanView.swift
//  Foodie
//
//  Created by AI Assistant.
//

import SwiftUI
import MapKit
import UIKit

struct MealPlanView: View {
    @StateObject private var vm = MealPlanViewModel()
    @State private var showingPermissionAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    mapSection
                    contentSection
                }
                .padding()
            }
            .background(AppTheme.background)
            .navigationTitle("Meal Planning")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Location Access Needed", isPresented: $showingPermissionAlert) {
                Button("Settings") { openSettings() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enable location access to find grocery options near you.")
            }
            .onChange(of: vm.phase) { _, newValue in
                // Show the alert only on actual denial; dismiss otherwise
                showingPermissionAlert = (newValue == .permissionDenied)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Plan your week")
                .font(.title2).bold()
            Text("Discover nearby stores and smart food picks tailored to you")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var mapSection: some View {
        ZStack {
            Map(coordinateRegion: $vm.region, annotationItems: vm.places) { place in
                MapMarker(coordinate: place.coordinate, tint: .accentColor)
            }
            .frame(height: 240)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.6), lineWidth: 0.5)
            )

            switch vm.phase {
            case .idle:
                placeholderOverlay
            case .requestingLocation:
                loadingOverlay
            case .loading:
                loadingOverlay
            case .ready:
                Color.clear
            case .failed(let message):
                failureOverlay(message: message)
            case .permissionDenied:
                placeholderOverlay
            }
        }
    }

    private var placeholderOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "map")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Find your local staples")
                .font(.title3).bold()
            Text("We’ll highlight nearby stores and smart picks once you start searching.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 28)
            Button {
                startSearch()
            } label: {
                Text("Start Searching")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppTheme.primary)
                    .foregroundStyle(Color.white)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var loadingOverlay: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Gathering nearby options…")
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func failureOverlay(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundStyle(.orange)
            Text("Something went wrong")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button {
                vm.refreshData()
            } label: {
                Text("Try Again")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(AppTheme.primary)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if vm.phase == .idle || vm.phase == .requestingLocation {
                Text("Tap start searching to populate nearby options.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                placeholderLists
            } else if vm.phase == .permissionDenied {
                permissionDeniedView
            } else if vm.phase == .ready || vm.phase == .loading {
                tabPicker
                contentLists
            }
        }
    }

    private var placeholderLists: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nearby places preview")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(0..<3) { index in
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.card)
                    .frame(height: 88)
                    .overlay(
                        ShimmerView(id: index)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    )
            }
        }
    }

    private var contentLists: some View {
        Group {
            if vm.selectedTab == .places {
                placesList
            } else {
                VStack(spacing: 16) {
                    createInstacartButton
                    if vm.isLoadingFoods {
                        foodsSkeletonList
                    } else if vm.foods.isEmpty {
                        foodsEmptyState
                    } else {
                        foodsList
                    }
                }
            }
        }
    }

    private var tabPicker: some View {
        Picker("Options", selection: $vm.selectedTab) {
            Text("Places").tag(MealPlanViewModel.Tab.places)
            Text("Foods").tag(MealPlanViewModel.Tab.foods)
        }
        .pickerStyle(.segmented)
    }

    private var placesList: some View {
        VStack(spacing: 12) {
            ForEach(vm.places) { place in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(place.name)
                            .font(.headline)
                        Spacer()
                        Text(distanceLabel(for: place.distanceMeters))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(place.address)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack {
                        Text(place.category)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.1))
                            .clipShape(Capsule())
                        Spacer()
                        if let url = place.doorDashURL {
                            Link(destination: url) {
                                doorDashIcon()
                            }
                            .accessibilityLabel("DoorDash")
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private var foodsList: some View {
        VStack(spacing: 12) {
            ForEach(vm.foods) { food in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(food.name)
                            .font(.headline)
                        Spacer()
                        Text(priceLabel(for: food.estimatedPrice))
                            .font(.headline)
                    }
                    Text("From \(food.storeName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let quantity = food.quantityHint {
                        Text("Qty: \(quantity)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(food.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let url = food.doorDashURL {
                        Link(destination: url) {
                            doorDashIcon()
                        }
                        .accessibilityLabel("DoorDash")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private var foodsSkeletonList: some View {
        VStack(spacing: 12) {
            ForEach(0..<4) { index in
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.card)
                    .frame(height: 96)
                    .overlay(
                        ShimmerView(id: index)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    )
            }
        }
    }

    private var foodsEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "leaf")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("No recommendations yet")
                .font(.headline)
            Text("Tap refresh to try again or adjust your preferences.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 12) {
            Text("Location is turned off")
                .font(.headline)
            Text("Allow Foodie to use your location so we can surface nearby grocery options.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button {
                openSettings()
            } label: {
                Text("Open Settings")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(AppTheme.primary)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func startSearch() {
        _ = vm.startSearching()
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func distanceLabel(for meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters)) m"
        } else {
            return String(format: "%.1f km", meters / 1000)
        }
    }

    private func priceLabel(for price: Double?) -> String {
        guard let price else { return "$–" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: price)) ?? String(format: "$%.2f", price)
    }

    private func doorDashIcon(size: CGFloat = 18) -> some View {
        Group {
            if UIImage(named: "doordash") != nil {
                Image("doordash")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            } else {
                Image(systemName: "shippingbox")
                    .font(.system(size: size))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.red.opacity(0.08))
        .clipShape(Capsule())
    }

    private var configureInstacartAlert: Alert {
        Alert(title: Text("Instacart API Key Needed"),
              message: Text("Add your Instacart API key in Settings to create shopping lists."),
              dismissButton: .default(Text("OK")))
    }

    @State private var showingConfigureAlert = false
    @State private var isCreatingList = false
    @State private var creationError: String?

    private var createInstacartButton: some View {
        Button {
            Task { await createInstacartListTapped() }
        } label: {
            HStack {
                if isCreatingList { ProgressView() }
                Text("Create Instacart Cart")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(vm.foods.isEmpty || isCreatingList)
        .alert(isPresented: Binding(get: { showingConfigureAlert }, set: { showingConfigureAlert = $0 })) {
            Alert(title: Text("Instacart API Key Needed"),
                  message: Text("Add your Instacart API key in Settings to create shopping lists."),
                  dismissButton: .default(Text("OK")))
        }
        .alert(item: Binding(get: {
            creationError.map { IdentifiedError(message: $0) }
        }, set: { newValue in
            creationError = newValue?.message
        })) { error in
            Alert(title: Text("Unable to create list"), message: Text(error.message), dismissButton: .default(Text("OK")))
        }
    }

    private struct IdentifiedError: Identifiable { let id = UUID(); let message: String }

    private func createInstacartListTapped() async {
        guard let coordinate = vm.currentCoordinate else {
            creationError = "We need a current location before generating a cart."
            return
        }

        guard (UserPreferencesStore.shared.loadInstacartApiKey() ?? "").isEmpty == false else {
            showingConfigureAlert = true
            return
        }

        isCreatingList = true
        do {
            let list = try await InstacartIntegrationService.shared.createShoppingList(from: vm.foods,
                                                                                       title: "Weekly Shopping",
                                                                                       coordinate: coordinate)
            ShoppingListStore.shared.add(list)
        } catch {
            creationError = error.localizedDescription
        }
        isCreatingList = false
    }
}

private struct ShimmerView: View {
    let id: Int
    @State private var phase: CGFloat = -120

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(colors: [Color.gray.opacity(0.15),
                                                 Color.gray.opacity(0.25),
                                                 Color.gray.opacity(0.15)],
                                       startPoint: .leading,
                                       endPoint: .trailing)
                    )
                    .mask(
                        Rectangle()
                            .fill(LinearGradient(colors: [.clear, .black, .clear],
                                                 startPoint: .leading,
                                                 endPoint: .trailing))
                            .offset(x: phase)
                    )
                    .animation(.linear(duration: 1.2).repeatForever(autoreverses: false), value: phase)
            )
            .onAppear {
                // Stagger animations slightly using id
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15 * Double(id)) {
                    phase = 120
                }
            }
    }
}

#Preview {
    NavigationStack { MealPlanView() }
}



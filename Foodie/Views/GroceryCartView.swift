//
//  GroceryCartView.swift
//  Foodie
//
//

import SwiftUI
import CoreLocation

struct GroceryCartView: View {
    @State private var cart: GroceryCartGenerator.GroceryCart?
    @State private var isGenerating = false
    @State private var isOrdering = false
    @State private var errorMessage: String?
    @State private var showingSuccess = false
    
    var body: some View {
        ZStack {
            if let cart = cart {
                cartContent(cart)
            } else {
                emptyState
            }
        }
        .background(AppTheme.background)
        .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .alert("Success!", isPresented: $showingSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your cart has been sent to Instacart. Check the app to complete your order!")
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            if isGenerating {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Generating your cart...")
                        .font(.title3).bold()
                    Text("Analyzing your eating habits and preferences")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(40)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "cart.circle")
                        .font(.system(size: 80))
                        .foregroundStyle(AppTheme.primary.opacity(0.7))
                    
                    Text("No cart yet")
                        .font(.title2).bold()
                    
                    Text("Generate a smart grocery list based on your eating history and preferences")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 40)
                    
                    Button {
                        Task { await generateCart() }
                    } label: {
                        Label("Generate Cart", systemImage: "sparkles")
                            .font(.headline)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(AppTheme.primary)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                    .padding(.top, 8)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func cartContent(_ cart: GroceryCartGenerator.GroceryCart) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                header(cart)
                
                itemsList(cart)
                
                orderButton
            }
            .padding()
        }
    }
    
    private func header(_ cart: GroceryCartGenerator.GroceryCart) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(cart.title)
                        .font(.title2).bold()
                    Text("\(cart.items.count) items • Generated \(formatRelativeDate(cart.generatedAt))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    Task { await generateCart() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 20))
                        .foregroundStyle(AppTheme.primary)
                }
                .disabled(isGenerating)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func itemsList(_ cart: GroceryCartGenerator.GroceryCart) -> some View {
        VStack(spacing: 16) {
            let grouped = Dictionary(grouping: cart.items) { $0.category }
            let sortedCategories = grouped.keys.sorted()
            
            ForEach(sortedCategories, id: \.self) { category in
                VStack(alignment: .leading, spacing: 12) {
                    Text(category)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    ForEach(grouped[category] ?? []) { item in
                        ItemRow(item: item, onToggle: {
                            toggleItem(item)
                        })
                    }
                }
            }
        }
    }
    
    private var orderButton: some View {
        VStack(spacing: 12) {
            Button {
                Task { await orderOnInstacart() }
            } label: {
                HStack {
                    if isOrdering {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    }
                    Text(isOrdering ? "Creating order..." : "Order on Instacart")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(isOrdering || cart?.items.isEmpty == true)
            
            Text("One-click checkout via Instacart")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private func generateCart() async {
        isGenerating = true
        defer { isGenerating = false }
        
        do {
            let location = LocationProvider.shared.lastKnownLocation
            let coordinate = location?.coordinate
            
            let newCart = try await GroceryCartGenerator.shared.generateCart(coordinate: coordinate)
            
            await MainActor.run {
                self.cart = newCart
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func toggleItem(_ item: GroceryCartGenerator.GroceryItem) {
        guard let currentCart = cart else { return }
        
        if let index = currentCart.items.firstIndex(where: { $0.id == item.id }) {
            var updatedItems = currentCart.items
            updatedItems[index].isChecked.toggle()
            cart = GroceryCartGenerator.GroceryCart(
                id: currentCart.id,
                items: updatedItems,
                generatedAt: currentCart.generatedAt,
                title: currentCart.title
            )
        }
    }
    
    private func orderOnInstacart() async {
        guard let currentCart = cart else { return }
        guard let coordinate = LocationProvider.shared.lastKnownLocation?.coordinate else {
            errorMessage = "Location is required to create an Instacart order"
            return
        }
        
        isOrdering = true
        defer { isOrdering = false }
        
        do {
            // Convert to food recommendations format
            let foodRecommendations = currentCart.items.map { item in
                FoodRecommendation(
                    name: item.name,
                    estimatedPrice: nil,
                    storeName: "Local Store",
                    notes: item.notes ?? "",
                    quantityHint: item.quantity,
                    doorDashURL: nil
                )
            }
            
            let shoppingList = try await InstacartIntegrationService.shared.createShoppingList(
                from: foodRecommendations,
                title: currentCart.title,
                coordinate: coordinate
            )
            
            ShoppingListStore.shared.add(shoppingList)
            
            await MainActor.run {
                showingSuccess = true
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Item Row
private struct ItemRow: View {
    let item: GroceryCartGenerator.GroceryItem
    let onToggle: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                onToggle()
            } label: {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(item.isChecked ? .green : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.body)
                    .strikethrough(item.isChecked)
                    .foregroundStyle(item.isChecked ? .secondary : .primary)
                
                HStack(spacing: 8) {
                    Text(item.quantity)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let notes = item.notes {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        GroceryCartView()
    }
}


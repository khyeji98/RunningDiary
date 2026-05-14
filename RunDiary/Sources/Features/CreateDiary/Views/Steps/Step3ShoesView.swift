//
//  Step3ShoesView.swift
//  RunDiary
//

import ComposableArchitecture
import Models
import SwiftUI

struct Step3ShoesView: View {
    @Bindable var store: StoreOf<CreateDiaryFeature>
    @State private var selectedBrand: String = ""

    var body: some View {
        VStack(spacing: 0) {
            StepTitleLabel(L10n.recordStepTitleShoes)

            if store.isShoesLoading && store.shoes.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(spacing: 0) {
                    BrandList(
                        brands: brands,
                        selected: selectedBrand
                    ) { brand in
                        selectedBrand = brand
                        selectFirstShoe(in: brand)
                    }
                    .frame(width: 130)

                    Divider()

                    ShoeList(
                        shoes: shoesOfSelectedBrand,
                        selectedShoeId: store.selectedShoe?.id
                    ) { store.send(.updateSelectedShoe($0)) }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .onAppear { syncSelectedBrand() }
        .onChange(of: store.shoes) { _, _ in syncSelectedBrand() }
    }

    private var brands: [String] {
        Array(Set(store.shoes.map(\.brandName))).sorted()
    }

    private var shoesOfSelectedBrand: [Shoe] {
        store.shoes
            .filter { $0.brandName == selectedBrand }
            .sorted { $0.nameKo < $1.nameKo }
    }

    private func syncSelectedBrand() {
        guard selectedBrand.isEmpty else { return }
        let brand = store.selectedShoe?.brandName ?? brands.first ?? ""
        selectedBrand = brand
        if store.selectedShoe == nil {
            selectFirstShoe(in: brand)
        }
    }

    private func selectFirstShoe(in brand: String) {
        let first = store.shoes
            .filter { $0.brandName == brand }
            .sorted { $0.nameKo < $1.nameKo }
            .first
        guard let first else { return }
        store.send(.updateSelectedShoe(first))
    }
}

private struct BrandList: View {
    let brands: [String]
    let selected: String
    let onSelect: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(brands, id: \.self) { brand in
                    BrandRow(
                        brand: brand,
                        isSelected: brand == selected
                    ) {
                        onSelect(brand)
                    }
                }
            }
        }
        .background(Color.gray100.opacity(0.3))
    }
}

private struct BrandRow: View {
    let brand: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(brand)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.blue700 : Color.gray500)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .background(isSelected ? Color(.systemBackground) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

private struct ShoeList: View {
    let shoes: [Shoe]
    let selectedShoeId: String?
    let onSelect: (Shoe) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(shoes) { shoe in
                    ShoeRow(
                        shoe: shoe,
                        isSelected: shoe.id == selectedShoeId
                    ) {
                        onSelect(shoe)
                    }
                    Divider()
                }
            }
        }
    }
}

private struct ShoeRow: View {
    let shoe: Shoe
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(shoe.name)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.blue700 : Color.gray700)
                    .multilineTextAlignment(.leading)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.blue300)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

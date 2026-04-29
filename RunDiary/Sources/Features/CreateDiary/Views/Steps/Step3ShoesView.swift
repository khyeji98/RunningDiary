//
//  Step3ShoesView.swift
//  RunDiary
//

import ComposableArchitecture
import Models
import SwiftUI

struct Step3ShoesView: View {
    @Bindable var store: StoreOf<CreateDiaryFeature>
    @State private var selectedBrand: String

    init(store: StoreOf<CreateDiaryFeature>) {
        self.store = store
        let initialBrand = store.selectedShoe?.brand ?? Self.brands.first ?? ""
        self._selectedBrand = State(initialValue: initialBrand)
    }

    var body: some View {
        VStack(spacing: 0) {
            StepTitleLabel(L10n.recordStepTitleShoes)

            HStack(spacing: 0) {
                BrandList(
                    brands: Self.brands,
                    selected: selectedBrand
                ) { selectedBrand = $0 }
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

    private static let brands: [String] = {
        var seen: Set<String> = []
        return ShoeStorage.shoes.compactMap { shoe in
            seen.insert(shoe.brand).inserted ? shoe.brand : nil
        }
    }()

    private var shoesOfSelectedBrand: [ShoeModel] {
        ShoeStorage.shoes.filter { $0.brand == selectedBrand }
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
                    ) { onSelect(brand) }
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
            .background(isSelected ? Color(.systemBackground) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

private struct ShoeList: View {
    let shoes: [ShoeModel]
    let selectedShoeId: String?
    let onSelect: (ShoeModel) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(shoes) { shoe in
                    ShoeRow(
                        shoe: shoe,
                        isSelected: shoe.id == selectedShoeId
                    ) { onSelect(shoe) }
                    Divider()
                }
            }
        }
    }
}

private struct ShoeRow: View {
    let shoe: ShoeModel
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

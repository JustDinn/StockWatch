//
//  AddStockToGroupView.swift
//  StockWatch
//

import SwiftUI

// MARK: - Main View

struct AddStockToGroupView: View {

    let groupName: String
    @StateObject private var store: AddStockToGroupStore
    @State private var searchText = ""

    init(groupName: String, onConfirm: @escaping ([SearchResult]) -> Void) {
        self.groupName = groupName
        _store = StateObject(wrappedValue: AddStockToGroupStore(
            tickerUseCase: TickerUseCase(repository: CompositeTickerRepository()),
            onConfirm: onConfirm
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            FilledSearchBar(text: $searchText)
                .onChange(of: searchText) { _, newValue in
                    store.action(.search(newValue))
                }

            contentView
            selectButton
        }
        .navigationTitle("\(groupName)에 종목 추가")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var contentView: some View {
        if store.state.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = store.state.errorMessage {
            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(store.state.searchResults, id: \.displayTicker) { result in
                        AddStockRow(
                            result: result,
                            isSelected: store.state.selectedStocks.contains(result)
                        ) {
                            store.action(.toggleSelection(result))
                        }
                    }
                }
            }
        }
    }

    private var selectButton: some View {
        Button(action: { store.action(.confirmSelection) }) {
            Text("\(store.state.selectedStocks.count)개 선택")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(store.state.selectedStocks.isEmpty ? Color.blue.opacity(0.4) : Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(store.state.selectedStocks.isEmpty)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Row

private struct AddStockRow: View {

    let result: SearchResult
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(result.description.prefix(1)))
                        .font(.headline.bold())
                        .foregroundStyle(.blue)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(result.description)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(result.displayTicker)
                    .font(.caption)
                    .foregroundStyle(.blue)
            }

            Spacer()

            Image(systemName: isSelected ? "heart.fill" : "heart")
                .foregroundStyle(isSelected ? .red : Color(.systemGray3))
                .font(.title3)
                .onTapGesture { onToggle() }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    NavigationStack {
        AddStockToGroupView(groupName: "테스트") { _ in }
    }
}

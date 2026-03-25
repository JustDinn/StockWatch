//
//  AddStockToGroupView.swift
//  StockWatch
//

import SwiftUI
import Kingfisher

// MARK: - Main View

struct AddStockToGroupView: View {

    let groupName: String
    @StateObject private var store: AddStockToGroupStore
    @State private var searchText = ""

    init(groupName: String, onConfirm: @escaping ([SearchResult], [String: String]) -> Void) {
        self.groupName = groupName
        print("<< [AddStockToGroupView] init - groupName: \(groupName)")
        _store = StateObject(wrappedValue: AddStockToGroupStore(
            tickerUseCase: TickerUseCase(repository: CompositeTickerRepository()),
            fetchLogoUseCase: FetchStockLogoUseCase(repository: StockLogoRepository()),
            onConfirm: onConfirm
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            FilledSearchBar(text: $searchText)
                .onChange(of: searchText) { oldValue, newValue in
                    print("<< [AddStockToGroupView] onChange triggered - oldValue: '\(oldValue)' newValue: '\(newValue)'")
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
                .font(.pretendardSubheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(store.state.searchResults, id: \.displayTicker) { result in
                        AddStockRow(
                            result: result,
                            isSelected: store.state.selectedStocks.contains(result),
                            logoURL: store.state.logoURLs[result.ticker]
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
                .font(.pretendardHeadline)
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
    let logoURL: String?
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            logoView

            VStack(alignment: .leading, spacing: 2) {
                Text(result.description)
                    .font(.pretendardMedium(size: 15))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(result.displayTicker)
                    .font(.pretendardCaption)
                    .foregroundStyle(.blue)
            }

            Spacer()

            Image(systemName: isSelected ? "heart.fill" : "heart")
                .foregroundStyle(isSelected ? .red : Color(.systemGray3))
                .font(.pretendardTitle3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture { onToggle() }
    }

    @ViewBuilder
    private var logoView: some View {
        if let urlStr = logoURL, let url = URL(string: urlStr) {
            KFImage(url)
                .placeholder { initialsCircle }
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .clipShape(Circle())
        } else {
            initialsCircle
        }
    }

    private var initialsCircle: some View {
        Circle()
            .fill(Color.blue.opacity(0.15))
            .frame(width: 44, height: 44)
            .overlay(
                Text(String(result.description.prefix(1)))
                    .font(.pretendardBold(size: 17))
                    .foregroundStyle(.blue)
            )
    }
}

#Preview {
    NavigationStack {
        AddStockToGroupView(groupName: "테스트") { _, _ in }
    }
}

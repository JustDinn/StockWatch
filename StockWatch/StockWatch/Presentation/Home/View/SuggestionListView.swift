//
//  SuggestionListView.swift
//  StockWatch
//
//  Created by HyoTaek on 2/24/26.
//

import SwiftUI

// MARK: - SuggestionListView

struct SuggestionListView: View {

    // MARK: - Properties

    let results: [SearchResult]
    let searchQuery: String
    var onSelect: (SearchResult) -> Void = { _ in }

    // MARK: - Body

    var body: some View {
        if results.isEmpty && !searchQuery.isEmpty {
            emptyView
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(results, id: \.ticker) { result in
                        SuggestionRow(result: result)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onSelect(result)
                            }
                    }
                }
            }
        }
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("검색 결과가 없습니다")
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text("영문 종목명 또는 티커로 검색해주세요")
                Text("ex) 애플 → APPLE or AAPL")
                Text("      엔비디아 → NVIDIA or NVDA")
            }
            .font(.subheadline)
            .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - SuggestionRow

private struct SuggestionRow: View {
    let result: SearchResult

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(result.displayTicker)
                    .font(.headline)
                    .fontWeight(.bold)

                Text(result.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 12)
    }
}

#Preview("결과 있음") {
    SuggestionListView(
        results: [
            SearchResult(description: "Apple Inc.", displayTicker: "AAPL", ticker: "AAPL", type: "Common Stock"),
            SearchResult(description: "NVIDIA Corporation", displayTicker: "NVDA", ticker: "NVDA", type: "Common Stock")
        ],
        searchQuery: "AAPL"
    )
}

#Preview("결과 없음") {
    SuggestionListView(results: [], searchQuery: "애플")
}

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
    var onSelect: (SearchResult) -> Void = { _ in }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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

#Preview {
    SuggestionListView(results: [
        SearchResult(description: "Apple Inc.", displayTicker: "AAPL", ticker: "AAPL", type: "Common Stock"),
        SearchResult(description: "NVIDIA Corporation", displayTicker: "NVDA", ticker: "NVDA", type: "Common Stock")
    ])
}

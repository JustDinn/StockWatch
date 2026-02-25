//
//  SuggestionListView.swift
//  StockWatch
//
//  Created by HyoTaek on 2/24/26.
//

import SwiftUI

// MARK: - Model

private struct SuggestionStock: Identifiable {
    let id = UUID()
    let ticker: String
    let name: String
}

// MARK: - SuggestionListView

struct SuggestionListView: View {

    // MARK: - Properties

    private let suggestions: [SuggestionStock] = [
        SuggestionStock(ticker: "AAPL", name: "Apple Inc."),
        SuggestionStock(ticker: "NVDA", name: "NVIDIA Corporation"),
        SuggestionStock(ticker: "TQQQ", name: "ProShares UltraPro QQQ"),
        SuggestionStock(ticker: "SOXL", name: "Direxion Daily Semiconductor Bull 3X Shares"),
        SuggestionStock(ticker: "PLTR", name: "Palantir Technologies Inc.")
    ]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(suggestions) { stock in
                SuggestionRow(stock: stock)
            }
        }
    }
}

// MARK: - SuggestionRow

private struct SuggestionRow: View {
    let stock: SuggestionStock

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.ticker)
                    .font(.headline)
                    .fontWeight(.bold)

                Text(stock.name)
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
    SuggestionListView()
}

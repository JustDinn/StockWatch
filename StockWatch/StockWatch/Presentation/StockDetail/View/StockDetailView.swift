//
//  StockDetailView.swift
//  StockWatch
//

import SwiftUI

struct StockDetailView: View {

    @StateObject private var store: StockDetailStore

    init(ticker: String, companyName: String) {
        _store = StateObject(wrappedValue: StockDetailStore(ticker: ticker, companyName: companyName))
    }

    var body: some View {
        let state = store.state

        VStack(spacing: 24) {
            // Avatar + 종목 정보
            VStack(spacing: 8) {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 72, height: 72)
                    .overlay(
                        Text(state.initials)
                            .font(.title2.bold())
                            .foregroundStyle(.blue)
                    )

                Text(state.ticker)
                    .font(.title.bold())

                Text(state.companyName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // 가격 정보
            VStack(spacing: 4) {
                Text(state.formattedPrice)
                    .font(.largeTitle.bold())

                Text(state.formattedChangePercent)
                    .font(.headline)
                    .foregroundStyle(state.isPositiveChange ? .green : .red)
            }

            Spacer()
        }
        .padding()
        .navigationTitle(state.ticker)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        StockDetailView(ticker: "AAPL", companyName: "APPLE INC")
    }
}

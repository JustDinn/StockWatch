//
//  StockDetailView.swift
//  StockWatch
//

import SwiftUI

struct StockDetailView: View {

    @StateObject private var store: StockDetailStore

    init(ticker: String) {
        _store = StateObject(wrappedValue: StockDetailStore(ticker: ticker))
    }

    var body: some View {
        let state = store.state

        Group {
            if state.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = state.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                VStack(spacing: 24) {
                    // 로고 + 종목 정보
                    VStack(spacing: 8) {
                        logoView(state: state)

                        Text(state.ticker)
                            .font(.title.bold())

                        HStack(spacing: 4) {
                            Text(state.companyName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)

                            Button {
                                store.action(.toggleFavorite)
                            } label: {
                                Image(systemName: state.isFavorite ? "heart.fill" : "heart")
                                    .foregroundStyle(.red)
                            }
                        }
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
            }
        }
        .navigationTitle(state.ticker)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            store.action(.loadDetail)
        }
    }
    @ViewBuilder
    private func logoView(state: StockDetailState) -> some View {
        if !state.logoURL.isEmpty, let url = URL(string: state.logoURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .clipShape(Circle())
                default:
                    initialsView(state: state)
                }
            }
        } else {
            initialsView(state: state)
        }
    }

    @ViewBuilder
    private func initialsView(state: StockDetailState) -> some View {
        Circle()
            .fill(Color.blue.opacity(0.15))
            .frame(width: 72, height: 72)
            .overlay(
                Text(state.initials)
                    .font(.title2.bold())
                    .foregroundStyle(.blue)
            )
    }
}

#Preview {
    NavigationStack {
        StockDetailView(ticker: "AAPL")
    }
}

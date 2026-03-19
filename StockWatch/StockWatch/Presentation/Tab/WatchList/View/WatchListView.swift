//
//  WatchListView.swift
//  StockWatch
//

import SwiftUI
import SwiftData

/// WatchList 화면 진입점 — modelContext를 Environment에서 받아 ContentView에 전달한다.
struct WatchListView: View {

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        WatchListContentView(modelContext: modelContext)
    }
}

// MARK: - Content View

private struct WatchListContentView: View {

    @StateObject private var store: WatchListStore

    init(modelContext: ModelContext) {
        let repository = FavoriteRepository(modelContext: modelContext)
        _store = StateObject(wrappedValue: WatchListStore(
            fetchFavoritesUseCase: FetchFavoritesUseCase(repository: repository),
            toggleFavoriteUseCase: ToggleFavoriteUseCase(repository: repository)
        ))
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.state.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if store.state.tickers.isEmpty {
                    emptyView
                } else {
                    tickerList
                }
            }
            .navigationTitle("워치리스트")
            .navigationDestination(item: store.selectedTickerBinding) { ticker in
                StockDetailView(ticker: ticker)
            }
            .onAppear {
                store.action(.loadFavorites)
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("관심 종목이 없습니다")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("종목 상세 화면에서\n하트를 눌러 관심 종목을 추가해보세요")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var tickerList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(store.state.tickers, id: \.self) { ticker in
                    HStack {
                        Text(ticker)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Spacer()

                        Button {
                            store.action(.removeFavorite(ticker: ticker))
                        } label: {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        store.action(.selectTicker(ticker))
                    }
                }
            }
        }
    }
}

#Preview {
    WatchListView()
}

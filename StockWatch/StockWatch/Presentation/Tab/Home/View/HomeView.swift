//
//  HomeView.swift
//  StockWatch
//
//  Created by HyoTaek on 2/22/26.
//

import SwiftUI
import SwiftData

struct HomeView: View {

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HomeContentView(modelContext: modelContext)
    }
}

// MARK: - Content View

private struct HomeContentView: View {

    @StateObject private var store: HomeStore
    @ObservedObject private var deepLinkManager = DeepLinkManager.shared

    init(modelContext: ModelContext) {
        let checkUnreadUseCase = CheckUnreadNotificationUseCase(
            repository: NotificationHistoryRepository(modelContext: modelContext)
        )
        _store = StateObject(wrappedValue: HomeStore(
            tickerUseCase: TickerUseCase(repository: CompositeTickerRepository()),
            checkUnreadUseCase: checkUnreadUseCase
        ))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchBar(placeholder: "종목명 또는 티커를 검색하세요") { keyword in
                    store.action(.search(keyword))
                }
                .padding(.bottom, 8)

                if store.state.isLoading {
                    ProgressView()
                    Spacer()
                } else if let errorMessage = store.state.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .padding()
                    Spacer()
                } else {
                    SuggestionListView(
                        results: store.state.searchResults,
                        searchQuery: store.state.searchQuery,
                        onSelect: { result in
                            store.action(.selectStock(result))
                        }
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.action(.showNotificationHistory)
                    } label: {
                        Image(systemName: "bell")
                            .overlay(alignment: .topTrailing) {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 4, y: -4)
                                    .opacity(store.state.hasUnreadNotification ? 1 : 0)
                            }
                    }
                }
            }
            .onAppear {
                store.action(.onAppear)
            }
            .navigationDestination(item: store.selectedStockBinding) { result in
                StockDetailView(ticker: result.displayTicker)
            }
            .navigationDestination(isPresented: store.isShowingNotificationHistoryBinding) {
                NotificationHistoryView()
            }
            .navigationDestination(isPresented: store.isShowingDeepLinkBinding) {
                if let ticker = store.state.deepLinkTicker {
                    StockDetailView(ticker: ticker)
                }
            }
            .onChange(of: deepLinkManager.pendingTicker) { _, ticker in
                guard let ticker else { return }
                store.action(.navigateToStock(ticker))
                deepLinkManager.pendingTicker = nil
            }
        }
    }
}

#Preview {
    HomeView()
}

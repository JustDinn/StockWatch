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
            tickerUseCase: TickerUseCase(repository: TickerRepository()),
            checkUnreadUseCase: checkUnreadUseCase
        ))
    }

    var body: some View {
        NavigationStack {
            VStack {
                SearchBar(placeholder: "종목을 검색하세요") { keyword in
                    store.action(.search(keyword))
                }

                if store.state.isLoading {
                    ProgressView()
                } else if let errorMessage = store.state.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .padding()
                } else {
                    SuggestionListView(
                        results: store.state.searchResults,
                        onSelect: { result in
                            store.action(.selectStock(result))
                        }
                    )
                }

                Spacer()
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

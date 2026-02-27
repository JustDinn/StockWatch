//
//  HomeView.swift
//  StockWatch
//
//  Created by HyoTaek on 2/22/26.
//

import SwiftUI

struct HomeView: View {
    
    @StateObject private var store = HomeStore(
        tickerUseCase: TickerUseCase(
            repository: TickerRepository()
        )
    )
    
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
            .navigationDestination(item: store.selectedStockBinding) { result in
                StockDetailView(ticker: result.displayTicker, companyName: result.description)
            }
        }
    }
}

#Preview {
    HomeView()
}

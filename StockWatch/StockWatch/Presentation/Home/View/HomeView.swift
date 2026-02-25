//
//  HomeView.swift
//  StockWatch
//
//  Created by HyoTaek on 2/22/26.
//

import SwiftUI

struct HomeView: View {
    
    @StateObject private var store = HomeStore(
        searchTickerUseCase: SearchTickerUseCase(
            repository: SearchRepository()
        )
    )
    
    var body: some View {
        VStack {
            SearchBar(placeholder: "종목을 검색하세요") { keyword in
                store.action(.search(keyword))
            }
            
            if store.state.isLoading {
                ProgressView()
            }
            
            SuggestionListView()

            Spacer()
        }
    }
}

#Preview {
    HomeView()
}

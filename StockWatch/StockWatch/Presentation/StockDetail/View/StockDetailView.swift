//
//  StockDetailView.swift
//  StockWatch
//

import SwiftUI
import SwiftData
import Kingfisher

/// StockDetail 화면 진입점 — modelContext를 Environment에서 받아 Store를 구성한다.
struct StockDetailView: View {

    @Environment(\.modelContext) private var modelContext
    let ticker: String

    var body: some View {
        StockDetailContentView(store: makeStore())
    }

    private func makeStore() -> StockDetailStore {
        let repository = FavoriteRepository(modelContext: modelContext)
        return StockDetailStore(
            ticker: ticker,
            toggleFavoriteUseCase: ToggleFavoriteUseCase(repository: repository),
            checkFavoriteUseCase: CheckFavoriteUseCase(repository: repository)
        )
    }
}

// MARK: - Content View

/// Store를 @StateObject로 보유하는 실제 UI 컴포넌트
private struct StockDetailContentView: View {

    @StateObject var store: StockDetailStore

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

                        Text(state.companyName)
                            .font(.title.bold())

                        HStack(spacing: 4) {
                            Text(state.ticker)
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

                    // 전략 적용하기 버튼
                    Button {
                        store.action(.navigateToApplyStrategy)
                    } label: {
                        Label("전략 적용하기", systemImage: "chart.line.uptrend.xyaxis")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Spacer()
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: store.isShowingApplyStrategyBinding) {
            StrategyView(ticker: store.state.ticker)
        }
        .task {
            store.action(.loadDetail)
        }
    }
    
    @ViewBuilder
    private func logoView(state: StockDetailState) -> some View {
        if !state.logoURL.isEmpty, let url = URL(string: state.logoURL) {
            KFImage(url)
                .placeholder { initialsView(state: state) }
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .clipShape(Circle())
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

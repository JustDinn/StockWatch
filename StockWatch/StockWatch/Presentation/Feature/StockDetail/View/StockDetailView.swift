//
//  StockDetailView.swift
//  StockWatch
//

import SwiftUI
import SwiftData
import Kingfisher

/// StockDetail 화면 진입점 — modelContext를 Environment에서 받아 ContentView에 전달한다.
struct StockDetailView: View {

    @Environment(\.modelContext) private var modelContext
    let ticker: String

    var body: some View {
        StockDetailContentView(ticker: ticker, modelContext: modelContext)
            .toolbar(.hidden, for: .tabBar)
    }
}

// MARK: - Content View

/// Store를 @StateObject로 보유하는 실제 UI 컴포넌트
private struct StockDetailContentView: View {

    @StateObject private var store: StockDetailStore

    init(ticker: String, modelContext: ModelContext) {
        let repository = FavoriteRepository(modelContext: modelContext)
        _store = StateObject(wrappedValue: StockDetailStore(
            ticker: ticker,
            toggleFavoriteUseCase: ToggleFavoriteUseCase(repository: repository),
            checkFavoriteUseCase: CheckFavoriteUseCase(repository: repository)
        ))
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
                    HStack(spacing: 12) {
                        logoView(state: state)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(state.companyName)
                                    .font(.subheadline.bold())

                                Text(state.ticker)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.secondary)

                                Button {
                                    store.action(.toggleFavorite)
                                } label: {
                                    Image(systemName: state.isFavorite ? "heart.fill" : "heart")
                                        .foregroundStyle(.red)
                                }
                            }

                            // 가격 정보
                            HStack(spacing: 8) {
                                Text(state.formattedPrice)
                                    .font(.title2.bold())

                                Text(state.formattedChangePercent)
                                    .font(.subheadline)
                                    .foregroundStyle(state.isPositiveChange ? .green : .red)
                            }
                        }

                        Spacer()
                    }

                    // 캔들스틱 차트
                    if state.isChartLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 240)
                    } else if let data = state.candlestickData, !data.candles.isEmpty {
                        LightweightChartView(candles: data.candles)
                            .frame(maxWidth: .infinity, minHeight: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // 봉 주기 선택 탭
                    periodTabView(state: state)

                    // 전략 적용하기 버튼
                    Button {
                        store.action(.navigateToApplyStrategy)
                    } label: {
                        Text("알림 설정하기")
                            .frame(maxWidth: .infinity, minHeight: 36)
                    }
                    .buttonStyle(.borderedProminent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

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
    private func periodTabView(state: StockDetailState) -> some View {
        HStack(spacing: 0) {
            ForEach(ChartPeriod.allCases, id: \.self) { period in
                Button {
                    store.action(.selectPeriod(period))
                } label: {
                    Text(period.rawValue)
                        .font(.footnote.weight(
                            state.selectedPeriod == period ? .bold : .regular
                        ))
                        .foregroundStyle(
                            state.selectedPeriod == period
                                ? Color.primary
                                : Color.secondary
                        )
                        .frame(maxWidth: .infinity, minHeight: 28)
                        .background(
                            Group {
                                if state.selectedPeriod == period {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }

    @ViewBuilder
    private func logoView(state: StockDetailState) -> some View {
        if !state.logoURL.isEmpty, let url = URL(string: state.logoURL) {
            KFImage(url)
                .placeholder { initialsView(state: state) }
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .clipShape(Circle())
        } else {
            initialsView(state: state)
        }
    }

    @ViewBuilder
    private func initialsView(state: StockDetailState) -> some View {
        Circle()
            .fill(Color.blue.opacity(0.15))
            .frame(width: 48, height: 48)
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

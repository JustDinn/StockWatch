//
//  StockDetailStore.swift
//  StockWatch
//

import Foundation
import SwiftUI

/// StockDetail 화면 Store
@MainActor
final class StockDetailStore: ObservableObject {

    // MARK: - Properties

    @Published private(set) var state: StockDetailState
    private let fetchStockDetailUseCase: FetchStockDetailUseCaseProtocol
    private let fetchCandlestickUseCase: FetchCandlestickUseCaseProtocol
    private let toggleFavoriteUseCase: ToggleFavoriteUseCaseProtocol
    private let checkFavoriteUseCase: CheckFavoriteUseCaseProtocol
    private var chartTask: Task<Void, Never>?

    // MARK: - Init

    init(
        ticker: String,
        fetchStockDetailUseCase: FetchStockDetailUseCaseProtocol = FetchStockDetailUseCase(
            repository: StockDetailRepository()
        ),
        fetchCandlestickUseCase: FetchCandlestickUseCaseProtocol = FetchCandlestickUseCase(
            repository: CandlestickRepository()
        ),
        toggleFavoriteUseCase: ToggleFavoriteUseCaseProtocol,
        checkFavoriteUseCase: CheckFavoriteUseCaseProtocol
    ) {
        self.state = StockDetailState(ticker: ticker)
        self.fetchStockDetailUseCase = fetchStockDetailUseCase
        self.fetchCandlestickUseCase = fetchCandlestickUseCase
        self.toggleFavoriteUseCase = toggleFavoriteUseCase
        self.checkFavoriteUseCase = checkFavoriteUseCase
    }

    // MARK: - Action

    func action(_ intent: StockDetailIntent) {
        switch intent {
        case .loadDetail:
            loadDetail()
        case .dismiss:
            break
        case .toggleFavorite:
            persistToggleFavorite()
        case .navigateToApplyStrategy:
            state.isShowingApplyStrategy = true
        case .selectPeriod(let period):
            state.selectedPeriod = period
            chartTask?.cancel()
            chartTask = Task { await reloadChart(period: period) }
        }
    }

    var isShowingApplyStrategyBinding: Binding<Bool> {
        Binding(
            get: { self.state.isShowingApplyStrategy },
            set: { self.state.isShowingApplyStrategy = $0 }
        )
    }
}

// MARK: - Private

extension StockDetailStore {

    private func loadDetail() {
        state.isLoading = true
        state.isChartLoading = true
        state.errorMessage = nil
        state.chartErrorMessage = nil

        Task {
            // 즐겨찾기 상태, 주식 상세 정보, 캔들스틱 데이터를 병렬로 로드
            async let isFav = checkFavoriteUseCase.execute(ticker: state.ticker)
            async let detail = fetchDetail()
            async let candlestick = fetchCandlestick(period: state.selectedPeriod)

            state.isFavorite = await isFav

            switch await detail {
            case .success(let stockDetail):
                let koreanName = KoreanStockDictionary.shared.entries
                    .first(where: { $0.ticker == state.ticker })?.nameKo
                state.companyName = koreanName ?? stockDetail.companyName
                state.currentPrice = stockDetail.currentPrice
                state.priceChangePercent = stockDetail.priceChangePercent
                state.logoURL = stockDetail.logoURL
                state.currency = stockDetail.currency
            case .failure(let error):
                state.errorMessage = error.localizedDescription
            }

            switch await candlestick {
            case .success(let data):
                state.candlestickData = data
            case .failure(let error):
                state.chartErrorMessage = error.localizedDescription
            }

            state.isLoading = false
            state.isChartLoading = false
        }
    }

    private func fetchCandlestick(period: ChartPeriod) async -> Result<CandlestickData, Error> {
        do {
            let data = try await fetchCandlestickUseCase.execute(ticker: state.ticker, period: period)
            return .success(data)
        } catch {
            return .failure(error)
        }
    }

    private func reloadChart(period: ChartPeriod) async {
        state.isChartLoading = true
        state.chartErrorMessage = nil

        switch await fetchCandlestick(period: period) {
        case .success(let data):
            guard !Task.isCancelled else { return }
            state.candlestickData = data
        case .failure(let error):
            guard !Task.isCancelled else { return }
            state.chartErrorMessage = error.localizedDescription
        }

        state.isChartLoading = false
    }

    private func fetchDetail() async -> Result<StockDetail, Error> {
        do {
            let detail = try await fetchStockDetailUseCase.execute(ticker: state.ticker)
            return .success(detail)
        } catch {
            return .failure(error)
        }
    }

    /// 낙관적 UI 업데이트 후 SwiftData에 영구 저장
    /// 저장 실패 시 원래 상태로 롤백한다.
    private func persistToggleFavorite() {
        let previousState = state.isFavorite
        // 낙관적 업데이트: 즉시 UI 반영
        state.isFavorite.toggle()

        Task {
            do {
                let newState = try await toggleFavoriteUseCase.execute(ticker: state.ticker, companyName: state.companyName)
                state.isFavorite = newState
            } catch {
                // 실패 시 롤백
                state.isFavorite = previousState
            }
        }
    }
}

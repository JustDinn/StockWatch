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
    private let fetchGroupIdsForTickerUseCase: FetchGroupIdsForTickerUseCaseProtocol
    private let updateFavoriteGroupsUseCase: UpdateFavoriteGroupsUseCaseProtocol
    private var chartTask: Task<Void, Never>?
    private var toastDismissTask: Task<Void, Never>?
    private let indicatorManager = TechnicalIndicatorSettingsManager.shared

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
        checkFavoriteUseCase: CheckFavoriteUseCaseProtocol,
        fetchGroupIdsForTickerUseCase: FetchGroupIdsForTickerUseCaseProtocol,
        updateFavoriteGroupsUseCase: UpdateFavoriteGroupsUseCaseProtocol
    ) {
        self.state = StockDetailState(ticker: ticker)
        self.fetchStockDetailUseCase = fetchStockDetailUseCase
        self.fetchCandlestickUseCase = fetchCandlestickUseCase
        self.toggleFavoriteUseCase = toggleFavoriteUseCase
        self.checkFavoriteUseCase = checkFavoriteUseCase
        self.fetchGroupIdsForTickerUseCase = fetchGroupIdsForTickerUseCase
        self.updateFavoriteGroupsUseCase = updateFavoriteGroupsUseCase
    }

    // MARK: - Action

    func action(_ intent: StockDetailIntent) {
        switch intent {
        case .loadDetail:
            loadDetail()
        case .dismiss:
            break
        case .showFavoriteModal:
            state.isShowingFavoriteModal = true
        case .toggleFavorite:
            Task { await handleToggleFavorite() }
        case .reloadFavoriteStatus:
            reloadFavoriteStatus()
        case .undoRemoveFavorite:
            Task { await undoRemoveFavorite() }
        case .dismissToast:
            toastDismissTask?.cancel()
            state.isShowingToast = false
            state.toastMessage = nil
            state.undoInfo = nil
        case .navigateToApplyStrategy:
            state.isShowingApplyStrategy = true
        case .navigateToIndicatorSettings:
            state.isShowingIndicatorSettings = true
        case .selectPeriod(let period):
            state.selectedPeriod = period
            state.hasMoreOlderCandles = true
            state.isLoadingOlderCandles = false
            state.pendingOlderCandles = nil
            chartTask?.cancel()
            chartTask = Task { await reloadChart(period: period) }
        case .loadOlderCandles:
            guard !state.isLoadingOlderCandles, state.hasMoreOlderCandles else { return }
            chartTask = Task { await loadOlderCandles() }
        case .clearPendingOlderCandles:
            state.pendingOlderCandles = nil
        case .reloadIndicatorSettings:
            loadIndicatorSettings()
        }
    }

    var isShowingApplyStrategyBinding: Binding<Bool> {
        Binding(
            get: { self.state.isShowingApplyStrategy },
            set: { self.state.isShowingApplyStrategy = $0 }
        )
    }

    var isShowingIndicatorSettingsBinding: Binding<Bool> {
        Binding(
            get: { self.state.isShowingIndicatorSettings },
            set: { self.state.isShowingIndicatorSettings = $0 }
        )
    }

    var isFavoriteModalBinding: Binding<Bool> {
        Binding(
            get: { self.state.isShowingFavoriteModal },
            set: { newValue in
                self.state.isShowingFavoriteModal = newValue
                if !newValue { self.reloadFavoriteStatus() }
            }
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

        // 기술적 지표 설정 로드
        loadIndicatorSettings()

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

    private func loadOlderCandles() async {
        guard let existingCandles = state.candlestickData?.candles,
              let oldestCandle = existingCandles.first else { return }

        state.isLoadingOlderCandles = true
        state.pendingOlderCandles = nil

        do {
            let olderData = try await fetchCandlestickUseCase.fetchOlderCandles(
                ticker: state.ticker,
                period: state.selectedPeriod,
                before: oldestCandle.timestamp
            )
            guard !Task.isCancelled else { return }

            if olderData.candles.isEmpty {
                state.hasMoreOlderCandles = false
            } else {
                // 기존 캔들과 병합 (중복 제거, 시간순 정렬)
                let merged = (olderData.candles + existingCandles)
                    .reduce(into: [Date: Candle]()) { dict, candle in
                        dict[candle.timestamp] = candle
                    }
                    .values
                    .sorted { $0.timestamp < $1.timestamp }
                state.candlestickData = CandlestickData(ticker: state.ticker, candles: merged)
                state.pendingOlderCandles = olderData.candles
            }
        } catch {
            // 과거 데이터 로드 실패는 무시 (현재 차트 유지)
        }

        state.isLoadingOlderCandles = false
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

    private func reloadFavoriteStatus() {
        Task {
            state.isFavorite = await checkFavoriteUseCase.execute(ticker: state.ticker)
        }
    }

    private func handleToggleFavorite() async {
        guard state.isFavorite else {
            state.isShowingFavoriteModal = true
            return
        }

        let groupIds = await fetchGroupIdsForTickerUseCase.execute(ticker: state.ticker)

        if groupIds.count == 1 {
            let groupId = groupIds[0]
            do {
                try await updateFavoriteGroupsUseCase.execute(
                    ticker: state.ticker,
                    companyName: state.companyName,
                    logoURL: state.logoURL,
                    groupIds: []
                )
                state.isFavorite = false
                state.undoInfo = UndoFavoriteInfo(
                    ticker: state.ticker,
                    companyName: state.companyName,
                    logoURL: state.logoURL,
                    groupId: groupId
                )
                state.toastMessage = "워치리스트에서 삭제됐어요."
                state.isShowingToast = true
                scheduleToastDismiss()
            } catch {
                // 삭제 실패 시 무시
            }
        } else {
            state.isShowingFavoriteModal = true
        }
    }

    private func undoRemoveFavorite() async {
        guard let info = state.undoInfo else { return }
        toastDismissTask?.cancel()
        state.isShowingToast = false
        state.toastMessage = nil
        do {
            try await updateFavoriteGroupsUseCase.execute(
                ticker: info.ticker,
                companyName: info.companyName,
                logoURL: info.logoURL,
                groupIds: [info.groupId]
            )
            state.isFavorite = true
        } catch {
            // 복원 실패 시 무시
        }
        state.undoInfo = nil
    }

    private func scheduleToastDismiss() {
        toastDismissTask?.cancel()
        toastDismissTask = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            state.isShowingToast = false
            state.toastMessage = nil
            state.undoInfo = nil
        }
    }

    private func loadIndicatorSettings() {
        state.maConfiguration = indicatorManager.maConfiguration
        state.isMAEnabled = indicatorManager.isMAEnabled
    }
}

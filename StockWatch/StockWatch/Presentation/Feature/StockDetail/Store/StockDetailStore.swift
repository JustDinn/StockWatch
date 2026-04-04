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
            state.candlestickData = nil
            state.maCalculationCandles = nil
            state.isChartLoading = true
            state.chartErrorMessage = nil
            chartTask?.cancel()
            chartTask = Task { await reloadChart(period: period) }
        case .loadOlderCandles:
            guard !state.isLoadingOlderCandles, state.hasMoreOlderCandles else { return }
            chartTask = Task { await loadOlderCandles() }
        case .clearPendingOlderCandles:
            state.pendingOlderCandles = nil
        case .reloadIndicatorSettings:
            loadIndicatorSettings()
        case .toggleIndicatorLabelExpanded:
            state.isIndicatorLabelExpanded.toggle()
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
            let warmupCount = requiredWarmupCount()
            async let isFav = checkFavoriteUseCase.execute(ticker: state.ticker)
            async let detail = fetchDetail()
            async let candlestick = fetchCandlestick(period: state.selectedPeriod, warmupCount: warmupCount)

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
                applyFetchedCandles(data, warmupCount: warmupCount)
            case .failure(let error):
                state.chartErrorMessage = error.localizedDescription
            }

            state.isLoading = false
            state.isChartLoading = false
        }
    }

    private func fetchCandlestick(period: ChartPeriod, warmupCount: Int = 0) async -> Result<CandlestickData, Error> {
        do {
            let data = try await fetchCandlestickUseCase.execute(ticker: state.ticker, period: period, warmupCount: warmupCount)
            return .success(data)
        } catch {
            return .failure(error)
        }
    }

    /// warmup 캔들을 MA 계산 전용으로 분리하고, display 캔들만 candlestickData에 저장
    /// maCalculationCandles는 warmupCount와 무관하게 항상 전체 데이터를 저장:
    /// injectRSI에서 calcCandles = maCalculationCandles ?? candles 이므로
    /// nil이면 display candles(suffix로 잘린 일부)만으로 RSI를 계산해 값이 부족해짐
    private func applyFetchedCandles(_ data: CandlestickData, warmupCount: Int) {
        if warmupCount > 0, data.candles.count > warmupCount {
            state.maCalculationCandles = data.candles
            let displayCandles = Array(data.candles.dropFirst(warmupCount))
            state.candlestickData = CandlestickData(ticker: data.ticker, candles: displayCandles)
        } else {
            // warmupCount=0이거나 데이터가 warmupCount보다 적어 warmup 분리 불가한 경우
            // maCalculationCandles에 전체 저장 → MA/RSI 계산 정확도 보장
            // display는 최근 20개만 표시 → 일봉/주봉과 동일한 UX
            // (MA 포인트가 display 캔들 전체를 커버하도록 보장)
            state.maCalculationCandles = data.candles
            let displayCandles = Array(data.candles.suffix(20))
            state.candlestickData = CandlestickData(ticker: data.ticker, candles: displayCandles)
        }
    }

    private func requiredWarmupCount() -> Int {
        // 년봉은 MA warmup 불필요 (총 캔들 수가 적어(예: NVDA 28개) warmup을 잘라내면 절반이 사라짐)
        // 월봉은 warmup 적용: period=100, 200 등 긴 MA를 계산하려면 10y 범위 확장이 필요
        let isShortPeriod = state.selectedPeriod == .day || state.selectedPeriod == .week || state.selectedPeriod == .month

        var periods: [Int] = [0]
        if isShortPeriod {
            if state.isMAEnabled, let config = state.maConfiguration {
                periods.append(contentsOf: config.lines.map(\.period))
            }
            if state.isRSIEnabled, let config = state.rsiConfiguration {
                periods.append(config.line.period)
            }
        }
        return periods.max() ?? 0
    }

    private func loadOlderCandles() async {
        guard let existingCandles = state.candlestickData?.candles,
              let oldestCandle = existingCandles.first else { return }

        state.isLoadingOlderCandles = true
        state.pendingOlderCandles = nil

        do {
            // warmupCount=0: display 스크롤용 과거 데이터 조회에 warmup 불필요
            // MA 계산용 warmup은 prefetchOlderCandlesIfNeeded()에서 이미 확보됨
            let olderData = try await fetchCandlestickUseCase.fetchOlderCandles(
                ticker: state.ticker,
                period: state.selectedPeriod,
                before: oldestCandle.timestamp,
                warmupCount: 0
            )
            guard !Task.isCancelled else { return }

            if olderData.candles.isEmpty {
                state.hasMoreOlderCandles = false
            } else {
                let beforeTimestamp = oldestCandle.timestamp
                let displayOlderCandles = olderData.candles.filter { $0.timestamp < beforeTimestamp }
                guard !displayOlderCandles.isEmpty else {
                    state.hasMoreOlderCandles = false
                    state.isLoadingOlderCandles = false
                    return
                }

                // display 캔들: older display + 기존 display (중복 제거, 시간순)
                let mergedDisplay = (displayOlderCandles + existingCandles)
                    .reduce(into: [Date: Candle]()) { dict, candle in
                        dict[candle.timestamp] = candle
                    }
                    .values
                    .sorted { $0.timestamp < $1.timestamp }

                // MA 계산용: 전체 older + 기존 MA 캔들 (중복 제거, 시간순)
                let existingMACandles = state.maCalculationCandles ?? existingCandles
                let mergedForMA = (olderData.candles + existingMACandles)
                    .reduce(into: [Date: Candle]()) { dict, candle in
                        dict[candle.timestamp] = candle
                    }
                    .values
                    .sorted { $0.timestamp < $1.timestamp }

                state.candlestickData = CandlestickData(ticker: state.ticker, candles: mergedDisplay)
                state.maCalculationCandles = mergedForMA
                state.pendingOlderCandles = displayOlderCandles
            }
        } catch {
            // 과거 데이터 로드 실패는 무시 (현재 차트 유지)
        }

        state.isLoadingOlderCandles = false
    }

    /// MA 계산에 필요한 캔들 수가 부족할 때 자동으로 과거 데이터를 프리패치한다.
    /// API 한계로 초기 로드 시 충분한 데이터를 받지 못한 경우(예: 월봉 MA200)에 사용.
    /// display 캔들은 건드리지 않고 maCalculationCandles만 확장한다.
    private func prefetchOlderCandlesIfNeeded(requiredCount: Int) async {
        guard requiredCount > 0 else { return }
        let maxIterations = 5
        var iterations = 0
        while let maCandles = state.maCalculationCandles,
              maCandles.count < requiredCount,
              !Task.isCancelled,
              iterations < maxIterations {
            guard let oldest = maCandles.first else { break }
            do {
                let olderData = try await fetchCandlestickUseCase.fetchOlderCandles(
                    ticker: state.ticker,
                    period: state.selectedPeriod,
                    before: oldest.timestamp,
                    warmupCount: 0
                )
                guard !Task.isCancelled else { return }
                guard !olderData.candles.isEmpty else { break }
                // MA 계산용 캔들만 병합 (display 캔들은 변경하지 않음)
                let existingMACandles = state.maCalculationCandles ?? []
                let merged = (olderData.candles + existingMACandles)
                    .reduce(into: [Date: Candle]()) { dict, candle in dict[candle.timestamp] = candle }
                    .values
                    .sorted { $0.timestamp < $1.timestamp }
                state.maCalculationCandles = merged
            } catch {
                break
            }
            iterations += 1
        }
    }

    private func reloadChart(period: ChartPeriod) async {
        state.isChartLoading = true
        state.chartErrorMessage = nil

        let warmupCount = requiredWarmupCount()
        switch await fetchCandlestick(period: period, warmupCount: warmupCount) {
        case .success(let data):
            guard !Task.isCancelled else { return }
            applyFetchedCandles(data, warmupCount: warmupCount)
            // MA 계산에 필요한 캔들이 부족하면 자동으로 과거 데이터를 추가 로드
            // (예: 월봉 MA200은 200개 필요하지만 API 최대 121개 반환 → 자동 프리패치)
            await prefetchOlderCandlesIfNeeded(requiredCount: warmupCount)
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
        state.emaConfiguration = indicatorManager.emaConfiguration
        state.isEMAEnabled = indicatorManager.isEMAEnabled
        state.isVolumeEnabled = indicatorManager.isVolumeEnabled
        state.volumeMAConfiguration = indicatorManager.volumeMAConfiguration
        state.isRSIEnabled = indicatorManager.isRSIEnabled
        state.rsiConfiguration = indicatorManager.rsiConfiguration
    }
}

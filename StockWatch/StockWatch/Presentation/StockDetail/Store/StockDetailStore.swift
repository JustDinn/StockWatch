//
//  StockDetailStore.swift
//  StockWatch
//

import Foundation

/// StockDetail 화면 Store
@MainActor
final class StockDetailStore: ObservableObject {

    // MARK: - Properties

    @Published private(set) var state: StockDetailState
    private let fetchStockDetailUseCase: FetchStockDetailUseCaseProtocol
    private let toggleFavoriteUseCase: ToggleFavoriteUseCaseProtocol
    private let checkFavoriteUseCase: CheckFavoriteUseCaseProtocol

    // MARK: - Init

    init(
        ticker: String,
        fetchStockDetailUseCase: FetchStockDetailUseCaseProtocol = FetchStockDetailUseCase(
            repository: StockDetailRepository()
        ),
        toggleFavoriteUseCase: ToggleFavoriteUseCaseProtocol,
        checkFavoriteUseCase: CheckFavoriteUseCaseProtocol
    ) {
        self.state = StockDetailState(ticker: ticker)
        self.fetchStockDetailUseCase = fetchStockDetailUseCase
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
        }
    }
}

// MARK: - Private

extension StockDetailStore {

    private func loadDetail() {
        state.isLoading = true
        state.errorMessage = nil

        Task {
            // 즐겨찾기 상태와 주식 상세 정보를 병렬로 로드
            async let isFav = checkFavoriteUseCase.execute(ticker: state.ticker)
            async let detail = fetchDetail()

            state.isFavorite = await isFav

            switch await detail {
            case .success(let stockDetail):
                state.companyName = stockDetail.companyName
                state.currentPrice = stockDetail.currentPrice
                state.priceChangePercent = stockDetail.priceChangePercent
                state.logoURL = stockDetail.logoURL
            case .failure(let error):
                print("<< [StockDetailStore] error: \(error)")
                state.errorMessage = error.localizedDescription
            }
            state.isLoading = false
        }
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
                let newState = try await toggleFavoriteUseCase.execute(ticker: state.ticker)
                state.isFavorite = newState
            } catch {
                // 실패 시 롤백
                print("<< [StockDetailStore] toggleFavorite error: \(error)")
                state.isFavorite = previousState
            }
        }
    }
}

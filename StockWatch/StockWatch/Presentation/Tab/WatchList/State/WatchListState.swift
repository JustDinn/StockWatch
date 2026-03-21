//
//  WatchListState.swift
//  StockWatch
//

/// WatchList 행에 표시할 Mock 가격 데이터 (Presentation 레이어 전용)
struct WatchListRowMockData: Equatable {
    let currentPrice: Double
    let priceChangePercent: Double
    let currency: String          // "USD", "KRW"
}

/// WatchList 화면 UI 상태
struct WatchListState {
    var favorites: [FavoriteItem] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var selectedTicker: String? = nil  /// 선택된 종목 (nil이면 상세 화면 미표시)

    /// DB에서 로드된 그룹 목록
    var dbGroups: [WatchListGroup] = []
    var selectedGroupIndex: Int = 0

    /// DB 그룹명 목록
    var groups: [String] { dbGroups.map(\.name) }

    /// 티커 → Mock 가격 데이터
    var mockPriceData: [String: WatchListRowMockData] = [:]

    /// 결정적(deterministic) Mock 생성 — 티커 해시 기반으로 Preview 안정
    static func mockData(for ticker: String) -> WatchListRowMockData {
        let seed = abs(ticker.hashValue)
        let price = Double(50 + seed % 450) + Double(seed % 100) / 100.0
        let change = (Double(seed % 200) - 100.0) / 10.0  // -10.0 ~ +9.9%
        return WatchListRowMockData(
            currentPrice: price,
            priceChangePercent: change,
            currency: "USD"
        )
    }
}

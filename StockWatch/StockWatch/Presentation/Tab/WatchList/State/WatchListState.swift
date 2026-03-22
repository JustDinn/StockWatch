//
//  WatchListState.swift
//  StockWatch
//

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

    /// 수정 중인 그룹
    var groupToRename: WatchListGroup? = nil
    var renameGroupName: String = ""

    /// 티커 → 실제 가격 데이터
    var priceData: [String: StockQuote] = [:]
    var isPriceLoading: Bool = false

    /// 테스트 편의용 이니셜라이저
    init(favorites: [FavoriteItem] = []) {
        self.favorites = favorites
    }
}

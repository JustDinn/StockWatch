//
//  HomeState.swift
//  StockWatch
//

/// Home 화면 UI 상태
struct HomeState: Equatable {
    var searchResults: [SearchResult] = []       /// 검색 결과 목록
    var isLoading: Bool = false                  /// 로딩 상태
    var errorMessage: String? = nil              /// 에러 메시지 (nil이면 에러 없음)
    var selectedStock: SearchResult? = nil       /// 선택된 종목 (nil이면 상세 화면 미표시)
    var isShowingNotificationHistory: Bool = false /// 알림 수신 내역 화면 표시 여부
    var hasUnreadNotification: Bool = false       /// 읽지 않은 알림 존재 여부
    var deepLinkTicker: String? = nil             /// 딥링크로 이동할 종목 티커 (nil이면 미사용)
}

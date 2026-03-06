//
//  MyAlertsState.swift
//  StockWatch
//

/// MyAlerts 화면 UI 상태
struct MyAlertsState {
    /// 등록된 전략 조건 목록
    var conditions: [StockCondition]
    /// 로딩 중 여부
    var isLoading: Bool
    /// 에러 메시지
    var errorMessage: String?

    init() {
        self.conditions = []
        self.isLoading = false
        self.errorMessage = nil
    }
}

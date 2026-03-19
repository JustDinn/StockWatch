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
    /// 삭제 확인 Alert 표시 여부 및 삭제할 조건 ID
    var conditionToDelete: String?
    /// 편집을 위해 선택된 조건 (navigationDestination 트리거)
    var selectedConditionForEdit: StockCondition?

    init() {
        self.conditions = []
        self.isLoading = false
        self.errorMessage = nil
        self.conditionToDelete = nil
        self.selectedConditionForEdit = nil
    }
}

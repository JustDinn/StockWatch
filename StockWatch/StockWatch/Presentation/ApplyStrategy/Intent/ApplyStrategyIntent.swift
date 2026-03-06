//
//  ApplyStrategyIntent.swift
//  StockWatch
//

/// ApplyStrategy 화면 사용자 액션 정의
enum ApplyStrategyIntent {
    /// 전략 목록 로드
    case loadStrategies
    /// 전략 선택
    case selectStrategy(Strategy)
    /// SMA/EMA 단기 기간 변경
    case updateShortPeriod(Int)
    /// SMA/EMA 장기 기간 변경
    case updateLongPeriod(Int)
    /// RSI 기간 변경
    case updateRSIPeriod(Int)
    /// RSI 과매도 임계값 변경
    case updateOversoldThreshold(Double)
    /// RSI 과매수 임계값 변경
    case updateOverboughtThreshold(Double)
    /// 즉시 전략 평가 실행
    case evaluate
    /// 알림 등록 토글
    case toggleNotification
    /// 조건 저장
    case saveCondition
    /// 전략 선택 해제 (Back 버튼)
    case deselectStrategy
}

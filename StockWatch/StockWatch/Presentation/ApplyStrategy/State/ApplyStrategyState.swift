//
//  ApplyStrategyState.swift
//  StockWatch
//

import Foundation

/// ApplyStrategy 화면 UI 상태
struct ApplyStrategyState {
    /// 화면 진입 시 결정된 티커 (변경 없음)
    let ticker: String
    /// 전략 목록 (FetchStrategiesUseCase로 로드)
    var strategies: [Strategy]
    /// 현재 선택된 전략 (nil이면 전략 선택 단계)
    var selectedStrategy: Strategy?
    /// SMA/EMA 단기 기간
    var shortPeriod: Int
    /// SMA/EMA 장기 기간
    var longPeriod: Int
    /// RSI 기간
    var rsiPeriod: Int
    /// RSI 과매도 임계값
    var oversoldThreshold: Double
    /// RSI 과매수 임계값
    var overboughtThreshold: Double
    /// 즉시 확인 결과
    var signal: StrategySignal?
    /// 알림 등록 여부
    var isNotificationEnabled: Bool
    /// 알림 수신 시각 (KST 기준)
    var notificationTime: Date
    /// 로딩 중 여부
    var isLoading: Bool
    /// 평가 중 여부
    var isEvaluating: Bool
    /// 저장 성공 여부
    var isSaved: Bool
    /// FCM 토큰 수신 여부 (알림 ON 시 적용하기 버튼 활성화 조건)
    var isFCMTokenReady: Bool
    /// 에러 메시지
    var errorMessage: String?
    /// 편집 모드일 때 기존 조건 ID (nil이면 신규 생성, non-nil이면 업데이트)
    var existingConditionId: String?

    init(ticker: String) {
        self.ticker = ticker
        self.strategies = []
        self.selectedStrategy = nil
        self.shortPeriod = 20
        self.longPeriod = 50
        self.rsiPeriod = 14
        self.oversoldThreshold = 30
        self.overboughtThreshold = 70
        self.signal = nil
        self.isNotificationEnabled = false
        self.notificationTime = StockCondition.defaultNotificationTime()
        self.isLoading = false
        self.isEvaluating = false
        self.isSaved = false
        self.isFCMTokenReady = !FCMTokenManager.shared.currentToken.isEmpty
        self.errorMessage = nil
        self.existingConditionId = nil
    }

    /// 기존 조건으로 편집 모드 초기화
    init(condition: StockCondition, strategy: Strategy) {
        self.ticker = condition.ticker
        self.strategies = []
        self.selectedStrategy = strategy
        self.signal = nil
        self.isNotificationEnabled = condition.isNotificationEnabled
        self.notificationTime = condition.notificationTime
        self.isLoading = false
        self.isEvaluating = false
        self.isSaved = false
        self.isFCMTokenReady = !FCMTokenManager.shared.currentToken.isEmpty
        self.errorMessage = nil
        self.existingConditionId = condition.id

        switch condition.parameters {
        case let .sma(shortPeriod, longPeriod):
            self.shortPeriod = shortPeriod
            self.longPeriod = longPeriod
            self.rsiPeriod = 14
            self.oversoldThreshold = 30
            self.overboughtThreshold = 70
        case let .ema(shortPeriod, longPeriod):
            self.shortPeriod = shortPeriod
            self.longPeriod = longPeriod
            self.rsiPeriod = 14
            self.oversoldThreshold = 30
            self.overboughtThreshold = 70
        case let .rsi(period, oversoldThreshold, overboughtThreshold):
            self.shortPeriod = 20
            self.longPeriod = 50
            self.rsiPeriod = period
            self.oversoldThreshold = oversoldThreshold
            self.overboughtThreshold = overboughtThreshold
        }
    }

    /// 알림이 켜져 있으면 FCM 토큰이 있어야 적용 가능
    /// SMA/EMA의 경우 단기 기간이 장기 기간보다 작아야 적용 가능
    var canApply: Bool {
        let crossValid: Bool = {
            guard let strategy = selectedStrategy,
                  strategy.id == "sma_cross" || strategy.id == "ema_cross" else { return true }
            return shortPeriod < longPeriod
        }()
        let notificationValid = isNotificationEnabled ? isFCMTokenReady : true
        return crossValid && notificationValid
    }

    /// 현재 선택된 전략에 맞는 StrategyParameters 반환
    var currentParameters: StrategyParameters? {
        guard let strategy = selectedStrategy else { return nil }
        switch strategy.id {
        case "sma_cross":
            return .sma(shortPeriod: shortPeriod, longPeriod: longPeriod)
        case "ema_cross":
            return .ema(shortPeriod: shortPeriod, longPeriod: longPeriod)
        case "rsi":
            return .rsi(
                period: rsiPeriod,
                oversoldThreshold: oversoldThreshold,
                overboughtThreshold: overboughtThreshold
            )
        default:
            return nil
        }
    }
}

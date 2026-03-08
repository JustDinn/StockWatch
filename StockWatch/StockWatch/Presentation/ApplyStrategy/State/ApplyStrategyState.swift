//
//  ApplyStrategyState.swift
//  StockWatch
//

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
        self.isLoading = false
        self.isEvaluating = false
        self.isSaved = false
        self.isFCMTokenReady = !FCMTokenManager.shared.currentToken.isEmpty
        self.errorMessage = nil
    }

    /// 알림이 켜져 있으면 FCM 토큰이 있어야 적용 가능
    var canApply: Bool {
        isNotificationEnabled ? isFCMTokenReady : true
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

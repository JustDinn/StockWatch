//
//  StockDetailState.swift
//  StockWatch
//

import Foundation

/// 차트 봉 주기 선택
enum ChartPeriod: String, CaseIterable, Equatable {
    case day   = "일"
    case week  = "주"
    case month = "월"
    case year  = "년"
}

extension ChartPeriod {
    /// Yahoo Finance API range 파라미터
    var range: String {
        switch self {
        case .day:   return "6mo"
        case .week:  return "2y"
        case .month: return "5y"
        case .year:  return "20y"
        }
    }

    /// Yahoo Finance API interval 파라미터 (봉 단위)
    var interval: String {
        switch self {
        case .day:   return "1d"
        case .week:  return "1wk"
        case .month: return "1mo"
        case .year:  return "1y"
        }
    }
}

/// 되돌리기를 위한 삭제 전 즐겨찾기 정보
struct UndoFavoriteInfo: Equatable {
    let ticker: String
    let companyName: String
    let logoURL: String
    let groupId: UUID
}

/// StockDetail 화면 UI 상태
struct StockDetailState: Equatable {
    /// 티커 심볼 (예: "AAPL") - 화면 진입 시 결정, 이후 변경 없음
    let ticker: String
    /// 회사명 - API 응답 후 채워짐
    var companyName: String
    /// 현재가 - API 응답 후 채워짐
    var currentPrice: Double
    /// 변동률 - API 응답 후 채워짐
    var priceChangePercent: Double
    /// 통화 코드 - API 응답 후 채워짐 (예: "KRW", "USD", "JPY")
    var currency: String
    /// 로고 이미지 URL - API 응답 후 채워짐, 빈 문자열이면 이니셜 표시
    var logoURL: String
    /// 로딩 상태
    var isLoading: Bool
    /// 에러 메시지 (nil이면 에러 없음)
    var errorMessage: String?
    /// 관심 종목 여부
    var isFavorite: Bool
    /// 전략 적용 화면 표시 여부
    var isShowingApplyStrategy: Bool
    /// 기술적 지표 설정 화면 표시 여부
    var isShowingIndicatorSettings: Bool
    /// 관심 종목 그룹 선택 모달 표시 여부
    var isShowingFavoriteModal: Bool
    /// 캔들스틱 차트 데이터 (nil이면 차트 미표시)
    var candlestickData: CandlestickData?
    /// 차트 로딩 상태
    var isChartLoading: Bool
    /// 차트 에러 메시지 (주식 정보 에러와 분리)
    var chartErrorMessage: String?
    /// 선택된 봉 주기 (기본값: 일봉)
    var selectedPeriod: ChartPeriod
    /// 과거 데이터 로딩 중 여부
    var isLoadingOlderCandles: Bool
    /// 더 불러올 과거 데이터 존재 여부
    var hasMoreOlderCandles: Bool
    /// 차트에 주입할 과거 캔들 (nil이면 전체 갱신, 값이 있으면 prepend)
    var pendingOlderCandles: [Candle]?
    /// 토스트 표시 여부
    var isShowingToast: Bool
    /// 토스트 메시지
    var toastMessage: String?
    /// 되돌리기용 삭제 정보
    var undoInfo: UndoFavoriteInfo?
    /// 이동평균선 설정
    var maConfiguration: MAIndicatorConfiguration?
    /// 이동평균선 활성화 여부
    var isMAEnabled: Bool
    /// MA 계산 전용 캔들 (warmup 포함 전체). nil이면 candlestickData.candles로 계산
    var maCalculationCandles: [Candle]?
    /// 지수이동평균선 설정
    var emaConfiguration: EMAIndicatorConfiguration?
    /// 지수이동평균선 활성화 여부
    var isEMAEnabled: Bool
    /// 거래량 차트 활성화 여부
    var isVolumeEnabled: Bool
    /// 거래량 이동평균선 설정
    var volumeMAConfiguration: VolumeMAConfiguration?
    /// RSI 활성화 여부
    var isRSIEnabled: Bool
    /// RSI 설정
    var rsiConfiguration: RSIConfiguration?
    /// 차트 상단 지표 라벨 펼침 여부
    var isIndicatorLabelExpanded: Bool

    init(ticker: String) {
        self.ticker = ticker
        self.companyName = ""
        self.currentPrice = 0
        self.priceChangePercent = 0
        self.currency = ""
        self.logoURL = ""
        self.isLoading = false
        self.errorMessage = nil
        self.isFavorite = false
        self.isShowingApplyStrategy = false
        self.isShowingIndicatorSettings = false
        self.isShowingFavoriteModal = false
        self.candlestickData = nil
        self.isChartLoading = false
        self.chartErrorMessage = nil
        self.selectedPeriod = .day
        self.isLoadingOlderCandles = false
        self.hasMoreOlderCandles = true
        self.pendingOlderCandles = nil
        self.isShowingToast = false
        self.toastMessage = nil
        self.undoInfo = nil
        self.maConfiguration = nil
        self.isMAEnabled = false
        self.maCalculationCandles = nil
        self.emaConfiguration = nil
        self.isEMAEnabled = false
        self.isVolumeEnabled = false
        self.volumeMAConfiguration = nil
        self.isRSIEnabled = false
        self.rsiConfiguration = nil
        self.isIndicatorLabelExpanded = false
    }

    /// 가격 표시 문자열 (예: "₩193,900", "$150.25", "¥2,500"), 소수점 셋째자리에서 반올림
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        formatter.currencyCode = currency.isEmpty ? "USD" : currency
        formatter.maximumFractionDigits = 2
        formatter.roundingMode = .halfUp
        return formatter.string(from: NSNumber(value: currentPrice)) ?? "\(currentPrice)"
    }

    /// 변동률 표시 문자열 (예: "+1.69%", "-0.53%"), 소수점 셋째자리에서 반올림
    var formattedChangePercent: String {
        let sign = priceChangePercent >= 0 ? "+" : ""
        return String(format: "\(sign)%.2f%%", priceChangePercent)
    }

    /// 변동률이 양수이면 true (색상 분기용)
    var isPositiveChange: Bool {
        priceChangePercent >= 0
    }

    /// 아바타에 표시할 이니셜 (티커 앞 2글자, 예: "AA")
    var initials: String {
        String(ticker.prefix(2)).uppercased()
    }

    /// 차트 상단 오버레이에 표시할 활성화된 지표 라벨 목록
    var upperIndicatorLabels: [UpperIndicatorLabel] {
        var labels: [UpperIndicatorLabel] = []
        if isMAEnabled, let config = maConfiguration, !config.lines.isEmpty {
            labels.append(UpperIndicatorLabel(
                id: TechnicalIndicator.movingAverage.rawValue,
                name: TechnicalIndicator.movingAverage.title,
                values: config.lines.map { IndicatorValue(period: $0.period, colorHex: $0.colorHex) }
            ))
        }
        if isEMAEnabled, let config = emaConfiguration, !config.lines.isEmpty {
            labels.append(UpperIndicatorLabel(
                id: TechnicalIndicator.exponentialMovingAverage.rawValue,
                name: TechnicalIndicator.exponentialMovingAverage.title,
                values: config.lines.map { IndicatorValue(period: $0.period, colorHex: $0.colorHex) }
            ))
        }
        return labels
    }
}

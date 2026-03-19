//
//  StockDetailState.swift
//  StockWatch
//

import Foundation

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
    /// 캔들스틱 차트 데이터 (nil이면 차트 미표시)
    var candlestickData: CandlestickData?
    /// 차트 로딩 상태
    var isChartLoading: Bool
    /// 차트 에러 메시지 (주식 정보 에러와 분리)
    var chartErrorMessage: String?

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
        self.candlestickData = nil
        self.isChartLoading = false
        self.chartErrorMessage = nil
    }

    /// 가격 표시 문자열 (예: "₩193,900", "$150.25", "¥2,500")
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        formatter.currencyCode = currency.isEmpty ? "USD" : currency
        return formatter.string(from: NSNumber(value: currentPrice)) ?? "\(currentPrice)"
    }

    /// 변동률 표시 문자열 (예: "+1.69%", "-0.53%")
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
}

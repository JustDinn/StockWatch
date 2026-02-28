//
//  StockDetailState.swift
//  StockWatch
//

/// StockDetail 화면 UI 상태
struct StockDetailState: Equatable {
    /// 티커 심볼 (예: "AYI")
    let ticker: String
    /// 회사명 (예: "ACUITY BRANDS INC")
    let companyName: String
    /// 현재 가격 (더미 데이터)
    let currentPrice: Double
    /// 가격 변동률 (더미 데이터, 양수 = 상승, 음수 = 하락)
    let priceChangePercent: Double

    /// 가격 표시 문자열 (예: "$306.54")
    var formattedPrice: String {
        String(format: "$%.2f", currentPrice)
    }

    /// 변동률 표시 문자열 (예: "+1.06%", "-0.53%")
    var formattedChangePercent: String {
        let sign = priceChangePercent >= 0 ? "+" : ""
        return String(format: "\(sign)%.2f%%", priceChangePercent)
    }

    /// 변동률이 양수이면 true (색상 분기용)
    var isPositiveChange: Bool {
        priceChangePercent >= 0
    }

    /// 아바타에 표시할 이니셜 (티커 앞 2글자, 예: "AY")
    var initials: String {
        String(ticker.prefix(2)).uppercased()
    }
}

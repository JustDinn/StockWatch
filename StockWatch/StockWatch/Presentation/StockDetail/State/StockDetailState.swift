//
//  StockDetailState.swift
//  StockWatch
//

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
    /// 로고 이미지 URL - API 응답 후 채워짐, 빈 문자열이면 이니셜 표시
    var logoURL: String
    /// 로딩 상태
    var isLoading: Bool
    /// 에러 메시지 (nil이면 에러 없음)
    var errorMessage: String?

    init(ticker: String) {
        self.ticker = ticker
        self.companyName = ""
        self.currentPrice = 0
        self.priceChangePercent = 0
        self.logoURL = ""
        self.isLoading = false
        self.errorMessage = nil
    }

    /// 가격 표시 문자열 (예: "$150.25")
    var formattedPrice: String {
        String(format: "$%.2f", currentPrice)
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

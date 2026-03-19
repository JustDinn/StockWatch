//
//  String+TickerCurrency.swift
//  StockWatch
//

extension String {
    /// ticker suffix 기반 통화 코드 추론 (Yahoo Finance currency 필드 없을 때 fallback)
    var currencyFromTickerSuffix: String {
        if hasSuffix(".KS") || hasSuffix(".KQ") || hasSuffix(".KX") { return "KRW" }
        if hasSuffix(".T")   { return "JPY" }
        if hasSuffix(".HK")  { return "HKD" }
        if hasSuffix(".SS") || hasSuffix(".SZ") { return "CNY" }
        if hasSuffix(".L")   { return "GBP" }
        if hasSuffix(".PA")  { return "EUR" }
        if hasSuffix(".HNX") || hasSuffix(".HCM") { return "VND" }
        return "USD"
    }
}

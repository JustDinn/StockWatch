//
//  SparklineData.swift
//  StockWatch
//

/// 스파크라인 차트에 사용할 종가 데이터
struct SparklineData: Equatable {
    let ticker: String
    let closePrices: [Double]
}

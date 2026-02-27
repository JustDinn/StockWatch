//
//  SearchResult.swift
//  StockWatch
//

/// 종목 검색 결과를 나타내는 도메인 엔티티
struct SearchResult: Equatable, Hashable {
    let description: String     /// 종목 설명 (예: "APPLE INC")
    let displayTicker: String   /// 표시용 심볼 (예: "AAPL")
    let ticker: String          /// 심볼 (예: "AAPL")
    let type: String            /// 종목 타입 (예: "Common Stock")
}

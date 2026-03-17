//
//  KoreanStockEntry.swift
//  StockWatch
//

/// 한국어 종목명 ↔ 티커 매핑 엔트리
struct KoreanStockEntry: Decodable {
    let ticker: String
    let nameKo: String
    let nameEn: String
    let market: String
    let type: String
}

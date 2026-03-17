//
//  KoreanStockSearchResultMapper.swift
//  StockWatch
//

/// KoreanStockEntry → SearchResult 변환 매퍼.
enum KoreanStockSearchResultMapper {
    static func map(_ entry: KoreanStockEntry) -> SearchResult {
        SearchResult(
            description: entry.nameKo,
            displayTicker: entry.ticker,
            ticker: entry.ticker,
            type: entry.type
        )
    }
}

//
//  SearchResultMapper.swift
//  StockWatch
//

/// SymbolSearchItemDTO → SearchResult 변환 Mapper
enum SearchResultMapper {

    /// 단일 DTO를 Entity로 변환
    static func map(_ dto: TickerSearchItemDTO) -> SearchResult {
        SearchResult(
            description: dto.description,
            displayTicker: dto.displayTicker,
            ticker: dto.ticker,
            type: dto.type
        )
    }
}

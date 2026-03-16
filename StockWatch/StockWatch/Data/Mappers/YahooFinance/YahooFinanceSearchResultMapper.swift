//
//  YahooFinanceSearchResultMapper.swift
//  StockWatch
//

enum YahooFinanceSearchResultMapper {
    static func map(_ dto: YahooFinanceSearchItemDTO) -> SearchResult {
        SearchResult(
            description: dto.longname ?? dto.shortname ?? dto.symbol,
            displayTicker: dto.symbol,
            ticker: dto.symbol,
            type: dto.quoteType ?? ""
        )
    }
}

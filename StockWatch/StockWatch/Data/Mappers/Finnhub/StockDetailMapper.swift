//
//  StockDetailMapper.swift
//  StockWatch
//

/// QuoteResponseDTO + StockProfileDTO → StockDetail 변환 Mapper
enum StockDetailMapper {

    static func map(
        ticker: String,
        quote: QuoteResponseDTO,
        profile: StockProfileDTO
    ) -> StockDetail {
        StockDetail(
            ticker: ticker,
            companyName: profile.name ?? ticker,
            currentPrice: quote.c,
            priceChangePercent: quote.dp ?? 0.0,    // 시장 폐장 시 null → 0으로 처리
            logoURL: profile.logo ?? ""
        )
    }
}

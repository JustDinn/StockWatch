//
//  YahooFinanceSearchDTO.swift
//  StockWatch
//

struct YahooFinanceSearchDTO: Decodable {
    let quotes: [YahooFinanceSearchItemDTO]
}

struct YahooFinanceSearchItemDTO: Decodable {
    let symbol: String
    let shortname: String?
    let longname: String?
    let quoteType: String?
    let exchange: String?
}

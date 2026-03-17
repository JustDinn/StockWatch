//
//  KoreanStockDictionary.swift
//  StockWatch
//

import Foundation

/// 번들의 korean_stocks.json을 1회 로드하여 메모리에 캐싱한다.
final class KoreanStockDictionary {
    static let shared = KoreanStockDictionary()

    private(set) var entries: [KoreanStockEntry] = []

    private init() {
        load()
    }

    private func load() {
        guard let url = Bundle.main.url(forResource: "korean_stocks", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else {
            return
        }

        struct Root: Decodable {
            let stocks: [KoreanStockEntry]
        }

        if let root = try? JSONDecoder().decode(Root.self, from: data) {
            entries = root.stocks
        } else if let flat = try? JSONDecoder().decode([KoreanStockEntry].self, from: data) {
            // 플랫 배열 형식도 지원
            entries = flat
        }
    }
}

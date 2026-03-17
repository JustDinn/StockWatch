//
//  KoreanStockSearchService.swift
//  StockWatch
//

/// 한국어 종목명으로 로컬 딕셔너리를 검색하는 서비스.
final class KoreanStockSearchService {
    private let dictionary: KoreanStockDictionary

    init(dictionary: KoreanStockDictionary = .shared) {
        self.dictionary = dictionary
    }

    /// 쿼리로 종목을 검색한다. 접두사 매칭 우선, 포함 매칭 후순위, 최대 10개 반환.
    func search(query: String) -> [KoreanStockEntry] {
        let entries = dictionary.entries
        var prefix: [KoreanStockEntry] = []
        var contains: [KoreanStockEntry] = []

        for entry in entries {
            if entry.nameKo.hasPrefix(query) {
                prefix.append(entry)
            } else if entry.nameKo.contains(query) {
                contains.append(entry)
            }
        }

        return Array((prefix + contains).prefix(10))
    }
}

extension String {
    /// 문자열에 한글(가-힣) 문자가 포함되어 있으면 true.
    var containsKorean: Bool {
        unicodeScalars.contains { $0.value >= 0xAC00 && $0.value <= 0xD7AF }
    }
}

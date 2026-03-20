//
//  FavoriteRepository.swift
//  StockWatch
//

import SwiftData
import Foundation

/// 관심 종목 Repository 구현체
/// SwiftData의 ModelContext를 통해 FavoriteStock을 CRUD한다.
final class FavoriteRepository: FavoriteRepositoryProtocol {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func isFavorite(ticker: String) async -> Bool {
        let descriptor = FetchDescriptor<FavoriteStock>(
            predicate: #Predicate { $0.ticker == ticker }
        )
        let results = (try? modelContext.fetch(descriptor)) ?? []
        return !results.isEmpty
    }

    func addFavorite(ticker: String, companyName: String) async throws {
        // 이미 존재하는 경우 중복 추가하지 않는다
        guard await !isFavorite(ticker: ticker) else { return }
        let favorite = FavoriteStock(ticker: ticker, companyName: companyName)
        modelContext.insert(favorite)
        try modelContext.save()
    }

    func removeFavorite(ticker: String) async throws {
        let descriptor = FetchDescriptor<FavoriteStock>(
            predicate: #Predicate { $0.ticker == ticker }
        )
        let results = (try? modelContext.fetch(descriptor)) ?? []
        results.forEach { modelContext.delete($0) }
        try modelContext.save()
    }

    func fetchAllFavorites() async -> [FavoriteItem] {
        let descriptor = FetchDescriptor<FavoriteStock>(
            sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
        )
        let results = (try? modelContext.fetch(descriptor)) ?? []
        return results.map { FavoriteItem(ticker: $0.ticker, companyName: $0.companyName, addedAt: $0.addedAt) }
    }
}

//
//  FavoriteRepository.swift
//  StockWatch
//

import SwiftData
import Foundation

/// 관심 종목 Repository 구현체
/// SwiftData의 ModelContext를 통해 FavoriteStock을 CRUD한다.
@MainActor
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
        guard await !isFavorite(ticker: ticker) else { return }
        let favorite = FavoriteStock(ticker: ticker, companyName: companyName)
        modelContext.insert(favorite)
        try modelContext.save()
    }

    func addFavorite(ticker: String, companyName: String, logoURL: String, groupIds: [UUID]) async throws {
        guard await !isFavorite(ticker: ticker) else { return }
        let favorite = FavoriteStock(ticker: ticker, companyName: companyName, logoURL: logoURL)
        let groups = fetchGroupModels(by: groupIds)
        favorite.groups = groups
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
        return results.map {
            FavoriteItem(
                ticker: $0.ticker,
                companyName: $0.companyName ?? "",
                addedAt: $0.addedAt,
                logoURL: $0.logoURL ?? "",
                groupIds: $0.groups.map(\.id)
            )
        }
    }

    func updateFavoriteGroups(ticker: String, logoURL: String, groupIds: [UUID]) async throws {
        let descriptor = FetchDescriptor<FavoriteStock>(
            predicate: #Predicate { $0.ticker == ticker }
        )
        guard let stock = (try? modelContext.fetch(descriptor))?.first else { return }
        if !logoURL.isEmpty { stock.logoURL = logoURL }
        stock.groups = fetchGroupModels(by: groupIds)
        try modelContext.save()
    }

    func fetchFavorites(in groupId: UUID) async -> [FavoriteItem] {
        let descriptor = FetchDescriptor<FavoriteStock>(
            sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
        )
        let results = (try? modelContext.fetch(descriptor)) ?? []
        return results
            .filter { $0.groups.contains(where: { $0.id == groupId }) }
            .map {
                FavoriteItem(
                    ticker: $0.ticker,
                    companyName: $0.companyName ?? "",
                    addedAt: $0.addedAt,
                    logoURL: $0.logoURL ?? "",
                    groupIds: $0.groups.map(\.id)
                )
            }
    }

    func fetchGroupIds(for ticker: String) async -> [UUID] {
        let descriptor = FetchDescriptor<FavoriteStock>(
            predicate: #Predicate { $0.ticker == ticker }
        )
        guard let stock = (try? modelContext.fetch(descriptor))?.first else { return [] }
        return stock.groups.map(\.id)
    }

    // MARK: - Private

    private func fetchGroupModels(by ids: [UUID]) -> [WatchListGroupModel] {
        guard !ids.isEmpty else { return [] }
        let descriptor = FetchDescriptor<WatchListGroupModel>()
        let all = (try? modelContext.fetch(descriptor)) ?? []
        return all.filter { ids.contains($0.id) }
    }
}

//
//  FetchFavoritesByGroupUseCaseProtocol.swift
//  StockWatch
//

import Foundation

protocol FetchFavoritesByGroupUseCaseProtocol {
    func execute(groupId: UUID) async -> [FavoriteItem]
}

//
//  FavoriteGroupModalState.swift
//  StockWatch
//

import Foundation

struct FavoriteGroupModalState {
    var ticker: String
    var companyName: String
    var logoURL: String
    var groups: [WatchListGroup] = []
    var selectedGroupIds: Set<UUID> = []
    var isLoading: Bool = false
    var isDismissed: Bool = false
}

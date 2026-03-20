//
//  FavoriteGroupModalIntent.swift
//  StockWatch
//

import Foundation

enum FavoriteGroupModalIntent {
    case loadGroups
    case toggleGroup(UUID)
    case createNewGroup(String)
    case confirm
    case dismiss
}

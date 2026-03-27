//
//  MAIndicatorIntent.swift
//  StockWatch
//

import Foundation

enum MAIndicatorIntent {
    case addPeriod
    case removePeriod(id: UUID)
    case updatePeriod(id: UUID, period: Int)
    case reset
    case confirm
}

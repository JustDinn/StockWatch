//
//  MAIndicatorIntent.swift
//  StockWatch
//

import Foundation

enum MAIndicatorIntent {
    case addLine
    case removeLine(id: UUID)
    case updatePeriod(id: UUID, period: Int)
    case reset
    case confirm
}

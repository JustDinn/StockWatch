//
//  MAIndicatorIntent.swift
//  StockWatch
//

import Foundation

enum MAIndicatorIntent {
    case addLine
    case removeLine(id: UUID)
    case updatePeriod(id: UUID, period: Int)
    case updateColor(id: UUID, colorHex: String)
    case updateLineWidth(id: UUID, lineWidth: Int)
    case updatePriceSource(id: UUID, priceSource: MAPriceSource)
    case reset
    case confirm
}

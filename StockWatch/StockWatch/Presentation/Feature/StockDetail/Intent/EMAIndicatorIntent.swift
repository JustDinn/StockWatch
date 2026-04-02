//
//  EMAIndicatorIntent.swift
//  StockWatch
//

import Foundation

enum EMAIndicatorIntent {
    case addLine
    case removeLine(id: UUID)
    case updatePeriod(id: UUID, period: Int)
    case updateColor(id: UUID, colorHex: String)
    case updateLineWidth(id: UUID, lineWidth: Int)
    case updatePriceSource(id: UUID, priceSource: EMAPriceSource)
    case reset
    case confirm
}

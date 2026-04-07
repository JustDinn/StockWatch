//
//  RSIIndicatorIntent.swift
//  StockWatch
//

import Foundation

enum RSIIndicatorIntent {
    case updatePeriod(Int)
    case updateLineColor(String)
    case updateLineWidth(Int)
    case toggleLineEnabled
    case updateUpperLevel(Int)
    case toggleUpperLevel
    case updateMiddleLevel(Int)
    case toggleMiddleLevel
    case updateLowerLevel(Int)
    case toggleLowerLevel
    case updateBackgroundColor(String)
    case toggleBackground
    case reset
    case confirm
}

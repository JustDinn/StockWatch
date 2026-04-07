//
//  VolumeIndicatorIntent.swift
//  StockWatch
//

import Foundation

enum VolumeIndicatorIntent {
    case toggleEnabled
    case updatePeriod(Int)
    case updateColor(String)
    case updateLineWidth(Int)
    case reset
    case confirm
}

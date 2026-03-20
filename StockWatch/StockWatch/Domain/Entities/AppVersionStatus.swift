//
//  AppVersionStatus.swift
//  StockWatch
//

enum AppVersionStatus {
    case upToDate
    case updateRequired(minimumVersion: String, storeURL: String)
}

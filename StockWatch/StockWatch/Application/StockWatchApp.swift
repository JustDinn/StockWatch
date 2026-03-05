//
//  StockWatchApp.swift
//  StockWatch
//
//  Created by HyoTaek on 2/22/26.
//

import SwiftUI
import SwiftData

@main
struct StockWatchApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: [FavoriteStock.self, SavedStrategy.self])
    }
}

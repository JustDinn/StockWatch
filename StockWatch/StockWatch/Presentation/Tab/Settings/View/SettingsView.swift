//
//  SettingsView.swift
//  StockWatch
//

import SwiftUI

struct SettingsView: View {

    @StateObject private var store = SettingsStore()

    var body: some View {
        NavigationStack {
            List {
                Section("차트") {
                    NavigationLink("캔들 설정") {
                        CandleSettingsView(store: store)
                            .toolbar(.hidden, for: .tabBar)
                    }
                }
            }
            .navigationTitle("설정")
        }
    }
}

#Preview {
    SettingsView()
}

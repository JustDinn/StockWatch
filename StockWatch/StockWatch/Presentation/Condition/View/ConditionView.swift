//
//  ConditionView.swift
//  StockWatch
//

import SwiftUI

struct StrategyItem: Identifiable {
    let id = UUID()
    let name: String
    let description: String
}

struct ConditionView: View {
    private let strategies: [StrategyItem] = [
        StrategyItem(name: "단순 이동평균선 크로스 전략", description: "SMA"),
        StrategyItem(name: "지수 이동평균선 크로스 전략", description: "EMA"),
        StrategyItem(name: "RSI 전략", description: "RSI"),
    ]

    var body: some View {
        List(strategies) { strategy in
            // TODO(human): 셀 내부 레이아웃을 구현해주세요
            Text(strategy.name)
        }
        .navigationTitle("조건 추가")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ConditionView()
    }
}

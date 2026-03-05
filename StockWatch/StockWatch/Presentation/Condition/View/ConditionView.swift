//
//  ConditionView.swift
//  StockWatch
//

import SwiftUI

struct ConditionView: View {
    var body: some View {
        Text("조건 추가")
            .navigationTitle("조건 추가")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ConditionView()
    }
}

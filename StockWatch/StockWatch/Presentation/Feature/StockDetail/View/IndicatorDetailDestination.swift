//
//  IndicatorDetailDestination.swift
//  StockWatch
//

import SwiftUI

/// 각 TechnicalIndicator에 대한 상세 설정 뷰로 라우팅합니다.
/// 새 지표의 상세 뷰가 추가되면 이 파일에 case만 추가하면 됩니다.
struct IndicatorDetailDestination: View {
    let indicator: TechnicalIndicator

    var body: some View {
        switch indicator {
        case .movingAverage:
            Text("이동평균선 상세 설정")
                .navigationTitle(indicator.title)
                .navigationBarTitleDisplayMode(.inline)
        case .volume:
            Text("거래량 상세 설정")
                .navigationTitle(indicator.title)
                .navigationBarTitleDisplayMode(.inline)
        case .rsi:
            Text("RSI 상세 설정")
                .navigationTitle(indicator.title)
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

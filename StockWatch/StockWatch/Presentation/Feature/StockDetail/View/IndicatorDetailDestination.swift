//
//  IndicatorDetailDestination.swift
//  StockWatch
//

import SwiftUI

/// 각 TechnicalIndicator에 대한 상세 설정 뷰로 라우팅합니다.
/// 새 지표의 상세 뷰가 추가되면 이 파일에 case만 추가하면 됩니다.
struct IndicatorDetailDestination: View {
    let indicator: TechnicalIndicator
    let onMAConfirm: ((MAIndicatorConfiguration) -> Void)?
    let initialMAState: MAIndicatorState?
    let onVolumeConfirm: ((VolumeMAConfiguration) -> Void)?
    let initialVolumeState: VolumeIndicatorState?
    let onRSIConfirm: ((RSIConfiguration) -> Void)?
    let initialRSIState: RSIIndicatorState?

    init(
        indicator: TechnicalIndicator,
        initialMAState: MAIndicatorState? = nil,
        onMAConfirm: ((MAIndicatorConfiguration) -> Void)? = nil,
        initialVolumeState: VolumeIndicatorState? = nil,
        onVolumeConfirm: ((VolumeMAConfiguration) -> Void)? = nil,
        initialRSIState: RSIIndicatorState? = nil,
        onRSIConfirm: ((RSIConfiguration) -> Void)? = nil
    ) {
        self.indicator = indicator
        self.initialMAState = initialMAState
        self.onMAConfirm = onMAConfirm
        self.initialVolumeState = initialVolumeState
        self.onVolumeConfirm = onVolumeConfirm
        self.initialRSIState = initialRSIState
        self.onRSIConfirm = onRSIConfirm
    }

    var body: some View {
        switch indicator {
        case .movingAverage:
            if let onConfirm = onMAConfirm {
                MAIndicatorDetailView(initialState: initialMAState, onConfirm: onConfirm)
            } else {
                Text("설정 오류")
                    .navigationTitle(indicator.title)
                    .navigationBarTitleDisplayMode(.inline)
            }
        case .volume:
            if let onConfirm = onVolumeConfirm {
                VolumeIndicatorDetailView(initialState: initialVolumeState, onConfirm: onConfirm)
            } else {
                Text("설정 오류")
                    .navigationTitle(indicator.title)
                    .navigationBarTitleDisplayMode(.inline)
            }
        case .rsi:
            if let onConfirm = onRSIConfirm {
                RSIIndicatorDetailView(initialState: initialRSIState, onConfirm: onConfirm)
            } else {
                Text("설정 오류")
                    .navigationTitle(indicator.title)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

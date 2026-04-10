//
//  OfflineLoadingView.swift
//  StockWatch
//

import SwiftUI

/// 네트워크가 끊긴 상태에서 로딩 중일 때 표시하는 안내 컴포넌트.
/// `ProgressView` 아래에 함께 배치하여 사용한다.
struct OfflineLoadingView: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.secondary)
            Text("인터넷 연결을 확인하고 있어요")
                .font(.pretendardSubheadline)
                .foregroundStyle(.secondary)
            Text("연결이 복구되면 자동으로 불러올게요")
                .font(.pretendardCaption)
                .foregroundStyle(.tertiary)
        }
        .padding(.top, 12)
    }
}

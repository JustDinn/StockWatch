//
//  NetworkErrorView.swift
//  StockWatch
//

import SwiftUI

/// 네트워크 요청 실패 시 표시하는 에러 안내 컴포넌트.
/// `OfflineLoadingView`와 동일한 스타일을 사용한다.
struct NetworkErrorView: View {

    let message: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.secondary)
            Text(message)
                .font(.pretendardSubheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
    }
}

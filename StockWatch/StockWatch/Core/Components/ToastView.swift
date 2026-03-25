//
//  ToastView.swift
//  StockWatch
//

import SwiftUI

/// 하단에 잠깐 표시되는 토스트 알림 컴포넌트
struct ToastView: View {

    let icon: String
    let message: String
    let actionLabel: String?
    let onAction: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.white)
                .font(.pretendardBody)

            Text(message)
                .font(.pretendardSubheadline)
                .foregroundStyle(.white)

            Spacer()

            if let actionLabel, let onAction {
                Button(action: onAction) {
                    Text(actionLabel)
                        .font(.pretendardBold(size: 15))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(red: 0.28, green: 0.28, blue: 0.30).opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 20)
    }
}

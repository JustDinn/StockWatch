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
                .font(.body)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white)

            Spacer()

            if let actionLabel, let onAction {
                Button(action: onAction) {
                    Text(actionLabel)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.gray.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 20)
    }
}

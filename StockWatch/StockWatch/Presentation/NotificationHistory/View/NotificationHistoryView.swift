//
//  NotificationHistoryView.swift
//  StockWatch
//

import SwiftUI
import SwiftData
import Kingfisher

/// 푸시 알림 수신 내역 화면
/// HomeView의 NavigationStack 내에서 push되므로 자체 NavigationStack 없음
struct NotificationHistoryView: View {

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NotificationHistoryContentView(modelContext: modelContext)
    }
}

// MARK: - Content View

private struct NotificationHistoryContentView: View {

    @StateObject private var store: NotificationHistoryStore

    init(modelContext: ModelContext) {
        let repository = NotificationHistoryRepository(modelContext: modelContext)
        _store = StateObject(wrappedValue: NotificationHistoryStore(
            fetchUseCase: FetchNotificationHistoryUseCase(repository: repository)
        ))
    }

    var body: some View {
        Group {
            if store.state.notifications.isEmpty {
                emptyView
            } else {
                notificationList
            }
        }
        .navigationTitle("알림")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: store.selectedNotificationBinding) { item in
            StockDetailView(ticker: item.ticker)
        }
        .task {
            store.action(.loadNotifications)
        }
    }

    // MARK: - Empty

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("받은 알림이 없습니다")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - List

    private var notificationList: some View {
        List {
            if !store.todayNotifications.isEmpty {
                Section("오늘") {
                    ForEach(store.todayNotifications) { item in
                        notificationRow(item)
                    }
                }
            }

            if !store.recentNotifications.isEmpty {
                Section("최근 7일") {
                    ForEach(store.recentNotifications) { item in
                        notificationRow(item)
                    }
                }
            }

            if !store.olderNotifications.isEmpty {
                Section("이전 알림") {
                    ForEach(store.olderNotifications) { item in
                        notificationRow(item)
                    }
                }
            }

            // 하단 안내 문구
            Section {
                Text("받은 소식은 30일 동안 보관됩니다.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Row

    private func notificationRow(_ item: NotificationItem) -> some View {
        Button {
            store.action(.selectNotification(item))
        } label: {
            HStack(spacing: 12) {
                // 종목 로고 아이콘
                logoIcon(ticker: item.ticker, logoURL: item.logoURL)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.strategyName)
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)

                        Spacer()

                        Text(relativeTime(item.receivedAt))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text("\(item.ticker) · \(item.body)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func logoIcon(ticker: String, logoURL: String) -> some View {
        if !logoURL.isEmpty, let url = URL(string: logoURL) {
            KFImage(url)
                .placeholder { initialsIcon(ticker: ticker) }
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .clipShape(Circle())
        } else {
            initialsIcon(ticker: ticker)
        }
    }

    private func initialsIcon(ticker: String) -> some View {
        let initials = String(ticker.prefix(2)).uppercased()
        return Circle()
            .fill(Color.blue.opacity(0.15))
            .frame(width: 44, height: 44)
            .overlay(
                Text(initials)
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
            )
    }

    private func relativeTime(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 {
            return "방금 전"
        } else if seconds < 3600 {
            return "\(seconds / 60)분 전"
        } else if seconds < 86400 {
            return "\(seconds / 3600)시간 전"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM월 dd일"
            formatter.locale = Locale(identifier: "ko_KR")
            return formatter.string(from: date)
        }
    }
}

#Preview {
    NavigationStack {
        NotificationHistoryView()
    }
    .modelContainer(for: NotificationHistoryModel.self, inMemory: true)
}

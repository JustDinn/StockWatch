//
//  MainTabView.swift
//  StockWatch
//

import SwiftUI

/// 앱 루트 탭 뷰
/// 홈(검색/전략 탐색)과 내 알림(등록된 조건 목록)으로 구성된다.
struct MainTabView: View {

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("홈", systemImage: "house")
                }

            WatchListView()
                .tabItem {
                    Label("워치리스트", systemImage: "heart")
                }

            MyAlertsView()
                .tabItem {
                    Label("내 알림", systemImage: "bell")
                }
        }
    }
}

#Preview {
    MainTabView()
}

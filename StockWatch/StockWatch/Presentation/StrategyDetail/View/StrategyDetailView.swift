//
//  StrategyDetailView.swift
//  StockWatch
//

import SwiftUI
import SwiftData

/// StrategyDetail 화면 진입점 — modelContext를 Environment에서 받아 Store를 구성한다.
struct StrategyDetailView: View {

    @Environment(\.modelContext) private var modelContext
    let strategy: Strategy

    var body: some View {
        StrategyDetailContentView(store: makeStore())
    }

    private func makeStore() -> StrategyDetailStore {
        let repository = SavedStrategyRepository(modelContext: modelContext)
        return StrategyDetailStore(
            strategy: strategy,
            toggleSavedStrategyUseCase: ToggleSavedStrategyUseCase(repository: repository),
            checkSavedStrategyUseCase: CheckSavedStrategyUseCase(repository: repository)
        )
    }
}

// MARK: - Content View

private struct StrategyDetailContentView: View {

    @StateObject var store: StrategyDetailStore

    var body: some View {
        let state = store.state

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 헤더
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(state.strategy.shortName)
                            .font(.title2.bold())
                            .foregroundStyle(.blue)

                        Spacer()

                        Text(state.strategy.category.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }

                    Text(state.strategy.name)
                        .font(.headline)
                }

                Divider()

                // 설명
                Text(state.strategy.description)
                    .font(.body)
                    .lineSpacing(6)

                Spacer(minLength: 20)

                // 저장 버튼
                Button {
                    store.action(.toggleSaved)
                } label: {
                    HStack {
                        Image(systemName: state.isSaved ? "bookmark.fill" : "bookmark")
                        Text(state.isSaved ? "저장됨" : "전략 저장")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(state.isSaved ? .gray : .blue)
            }
            .padding()
        }
        .navigationTitle(state.strategy.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            store.action(.loadSavedStatus)
        }
    }
}

#Preview {
    NavigationStack {
        StrategyDetailView(
            strategy: Strategy(
                id: "sma_cross",
                name: "단순 이동평균선 크로스 전략",
                shortName: "SMA",
                description: "테스트 설명",
                category: .movingAverage
            )
        )
    }
}

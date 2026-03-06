//
//  StrategyView.swift
//  StockWatch
//

import SwiftUI
import SwiftData

/// Strategy 카탈로그 화면 진입점 — modelContext를 Environment에서 받아 Store를 구성한다.
struct StrategyView: View {

    @Environment(\.modelContext) private var modelContext
    var ticker: String? = nil

    var body: some View {
        StrategyContentView(store: makeStore(), ticker: ticker)
    }

    private func makeStore() -> StrategyStore {
        let savedStrategyRepository = SavedStrategyRepository(modelContext: modelContext)
        return StrategyStore(
            fetchStrategiesUseCase: FetchStrategiesUseCase(
                repository: StrategyRepository()
            ),
            fetchSavedStrategyIdsUseCase: FetchSavedStrategyIdsUseCase(
                repository: savedStrategyRepository
            )
        )
    }
}

// MARK: - Content View

private struct StrategyContentView: View {

    @StateObject var store: StrategyStore
    var ticker: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: segmentBinding) {
                ForEach(StrategySegment.allCases, id: \.self) { segment in
                    Text(segment.rawValue).tag(segment)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            let strategies = store.state.displayedStrategies

            if store.state.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if strategies.isEmpty {
                Spacer()
                Text(store.state.selectedSegment == .saved
                     ? "저장된 전략이 없습니다"
                     : "전략이 없습니다")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                List(strategies) { strategy in
                    StrategyRow(strategy: strategy)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            store.action(.selectStrategy(strategy))
                        }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("전략 카탈로그")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: store.selectedStrategyBinding) { strategy in
            StrategyDetailView(strategy: strategy, ticker: ticker)
        }
        .task {
            store.action(.loadStrategies)
        }
    }

    private var segmentBinding: Binding<StrategySegment> {
        Binding(
            get: { store.state.selectedSegment },
            set: { store.action(.selectSegment($0)) }
        )
    }
}

// MARK: - Strategy Row

private struct StrategyRow: View {
    let strategy: Strategy

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(strategy.name)
                    .font(.headline)

                Spacer()

                Text(strategy.category.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
            }

            Text(strategy.shortName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        StrategyView()
    }
}

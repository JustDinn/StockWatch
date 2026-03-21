//
//  AddStockToGroupView.swift
//  StockWatch
//

import SwiftUI

// MARK: - Dummy Model

private struct DummyStock: Identifiable {
    let id: String
    let ticker: String
    let nameKo: String
    let nameEn: String
    let logoColor: Color
}

// MARK: - Main View

struct AddStockToGroupView: View {

    let groupName: String

    @State private var searchText = ""
    @State private var selectedTickers: Set<String> = []

    private let dummyStocks: [DummyStock] = [
        DummyStock(id: "000660", ticker: "000660", nameKo: "SK하이닉스", nameEn: "SK hynix", logoColor: .red),
        DummyStock(id: "005930", ticker: "005930", nameKo: "삼성전자", nameEn: "Samsung Electronics", logoColor: .blue),
        DummyStock(id: "035420", ticker: "035420", nameKo: "NAVER", nameEn: "NAVER Corp", logoColor: .green),
        DummyStock(id: "035720", ticker: "035720", nameKo: "카카오", nameEn: "Kakao Corp", logoColor: .yellow),
        DummyStock(id: "051910", ticker: "051910", nameKo: "LG화학", nameEn: "LG Chem", logoColor: .purple),
        DummyStock(id: "006400", ticker: "006400", nameKo: "삼성SDI", nameEn: "Samsung SDI", logoColor: .orange),
        DummyStock(id: "207940", ticker: "207940", nameKo: "삼성바이오로직스", nameEn: "Samsung Biologics", logoColor: .teal),
        DummyStock(id: "068270", ticker: "068270", nameKo: "셀트리온", nameEn: "Celltrion", logoColor: .indigo),
    ]

    private var filteredStocks: [DummyStock] {
        guard !searchText.isEmpty else { return dummyStocks }
        return dummyStocks.filter {
            $0.nameKo.localizedCaseInsensitiveContains(searchText)
            || $0.nameEn.localizedCaseInsensitiveContains(searchText)
            || $0.ticker.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            FilledSearchBar(text: $searchText)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredStocks) { stock in
                        AddStockRow(
                            stock: stock,
                            isSelected: selectedTickers.contains(stock.ticker)
                        ) {
                            toggleSelection(stock.ticker)
                        }
                    }
                }
            }

            selectButton
        }
        .navigationTitle("\(groupName)에 종목 추가")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var selectButton: some View {
        Button(action: { }) {
            Text("\(selectedTickers.count)개 선택")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(selectedTickers.isEmpty ? Color.blue.opacity(0.4) : Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(selectedTickers.isEmpty)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func toggleSelection(_ ticker: String) {
        if selectedTickers.contains(ticker) {
            selectedTickers.remove(ticker)
        } else {
            selectedTickers.insert(ticker)
        }
    }
}

// MARK: - Row

private struct AddStockRow: View {

    let stock: DummyStock
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(stock.logoColor.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(stock.nameKo.prefix(1)))
                        .font(.headline.bold())
                        .foregroundStyle(stock.logoColor)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(stock.nameKo)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                Text(stock.nameEn)
                    .font(.caption)
                    .foregroundStyle(.blue)
            }

            Spacer()

            Image(systemName: isSelected ? "heart.fill" : "heart")
                .foregroundStyle(isSelected ? .red : Color(.systemGray3))
                .font(.title3)
                .onTapGesture { onToggle() }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - DummyStock needs to be accessible in AddStockRow
// DummyStock is defined as private at file scope, so AddStockRow (also private) can access it fine.

#Preview {
    NavigationStack {
        AddStockToGroupView(groupName: "ㄱ")
    }
}

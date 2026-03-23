//
//  FilledSearchBar.swift
//  StockWatch
//

import SwiftUI

struct FilledSearchBar: View {

    @Binding var text: String
    var placeholder: String = "종목명/티커 검색"
    var onSearch: (String) -> Void = { _ in }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .onSubmit {
                    onSearch(text)
                }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

#Preview {
    FilledSearchBar(text: .constant(""))
}

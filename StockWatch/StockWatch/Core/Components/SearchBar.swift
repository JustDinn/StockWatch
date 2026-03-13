//
//  SearchBar.swift
//  StockWatch
//
//  Created by HyoTaek on 2/24/26.
//

import SwiftUI

struct SearchBar: View {
    
    // MARK: - Properties
    
    @State private var keyword = ""
    var placeholder = ""
    var onSearch: (String) -> Void = { _ in }
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField(placeholder, text: $keyword)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.characters)
                .onSubmit {
                    onSearch(keyword)
                }
        }
        .padding(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.gray, lineWidth: 1)
        )
            .padding(15)
    }
}

#Preview {
    SearchBar()
}

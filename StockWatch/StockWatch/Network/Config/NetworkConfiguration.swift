//
//  NetworkConfiguration.swift
//  StockWatch
//
//  Created by HyoTaek on 2/23/26.
//

import Foundation

struct NetworkConfiguration {
    
    /// API 타입에 따른 Base URL 반환
    /// - Parameter apiService: API 서비스
    /// - Returns: 해당 API의 Base URL
    static func baseURL(_ apiService: APIService) -> String {
        guard let url = Bundle.main.object(forInfoDictionaryKey: apiService.baseURLKey) as? String else {
            print("[Network] Warning: \(apiService.baseURLKey) not found in Info.plist. Using empty string.")
            return ""
        }
        return url
    }
}

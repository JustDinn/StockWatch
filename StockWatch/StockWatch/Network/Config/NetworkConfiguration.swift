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
            fatalError("Info.plist에서 \(apiService.baseURLKey)를 찾을 수 없습니다. xcconfig 파일을 확인해주세요.")
        }
        return url
    }
}

//
//  APIService.swift
//  StockWatch
//
//  Created by HyoTaek on 2/23/26.
//

/// 사용하는 API 정의
enum APIService {
    
    /// 한국투자증권 API
    case kis
    
    /// Info.plist에서 조회할 키값
    var baseURLKey: String {
        switch self {
        case .kis:
            "KIS_BASE_URL"
        }
    }
}

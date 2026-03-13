//
//  NetworkRouter.swift
//  StockWatch
//
//  Created by HyoTaek on 2/23/26.
//

import Alamofire

/// API 통신 Router가 채택하는 공통 프로토콜
protocol NetworkRouter {
    
    /// 사용할 API 서비스
    var apiService: APIService { get }
    
    /// API 경로
    var path: String { get }

    /// HTTP 메서드
    var method: HTTPMethod { get }

    /// 요청 헤더
    var headers: [String: String]? { get }

    /// 요청 파라미터 (Body 또는 Query String으로 전달될 데이터)
    var parameters: [String: Any]? { get }
    
    /// 파라미터 인코딩 방식
    var encoding: ParameterEncoding { get }
}

// MARK: - Property

extension NetworkRouter {
    
    /// Base URL (APIService에 따라 Info.plist에서 가져옴)
    var baseURL: String {
        return NetworkConfiguration.baseURL(apiService)
    }
    
    /// 전체 URL을 반환 (baseURL + path)
    var urlString: String {
        return baseURL + path
    }

    /// Alamofire HTTPHeaders로 변환
    var httpHeaders: HTTPHeaders? {
        guard let headers = headers else { return nil }
        return HTTPHeaders(headers)
    }
    
    /// 파라미터 인코딩 방식 기본 구현 (GET: URLEncoding, 나머지: JSONEncoding)
    var encoding: ParameterEncoding {
        return method == .get ? URLEncoding.default : JSONEncoding.default
    }
}

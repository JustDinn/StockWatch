//
//  NetworkError.swift
//  StockWatch
//
//  Created by HyoTaek on 2/23/26.
//

import Foundation

/// 네트워크 에러 타입 정의
enum NetworkError: Error {
    
    /// 400 - 잘못된 요청
    case badRequest
    
    /// 401 - 인증 실패 (토큰 만료, 잘못된 인증 정보)
    case unauthorized
    
    /// 403 - 접근 권한 없음
    case forbidden
    
    /// 404 - 요청한 리소스를 찾을 수 없음
    case notFound
    
    /// 500 - 서버 내부 오류
    case serverError
    
    /// 응답 데이터 디코딩 실패
    case decodingFailed
    
    /// 네트워크 연결 끊김 (인터넷 미연결, DNS 실패 등)
    case networkDisconnected
    
    /// 요청 시간 초과
    case timeout
    
    /// SSL/TLS 보안 연결 실패
    case sslError
    
    /// 요청이 명시적으로 취소됨 (화면 이탈 등)
    case requestCancelled
    
    /// 알 수 없는 오류
    case unknownError
}

extension NetworkError: LocalizedError {
    
    /// 사용자에게 표시할 에러 메시지
    var errorDescription: String? {
        switch self {
        case .badRequest:
            return "잘못된 요청입니다."
        case .unauthorized:
            return "인증에 실패했습니다."
        case .forbidden:
            return "접근 권한이 없습니다."
        case .notFound:
            return "요청한 정보를 찾을 수 없습니다."
        case .serverError:
            return "서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요."
        case .decodingFailed:
            return "데이터 처리 중 오류가 발생했습니다."
        case .networkDisconnected:
            return "인터넷 연결을 확인해주세요."
        case .timeout:
            return "요청 시간이 초과되었습니다. 다시 시도해주세요."
        case .sslError:
            return "보안 연결에 실패했습니다."
        case .requestCancelled:
            return nil
        case .unknownError:
            return "알 수 없는 오류가 발생했습니다."
        }
    }
}

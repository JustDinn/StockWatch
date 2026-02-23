//
//  NetworkService.swift
//  StockWatch
//
//  Created by HyoTaek on 2/23/26.
//

import Foundation
import Alamofire

protocol NetworkServiceProtocol {
    func request<T: Decodable>(router: some NetworkRouter, model: T.Type) async throws -> T
}

final class NetworkService: NetworkServiceProtocol {
    
    /// API 요청 함수
    func request<T: Decodable>(
        router: some NetworkRouter,
        model: T.Type
    ) async throws -> T {
        do {
            return try await AF.request(
                router.urlString,
                method: router.method,
                parameters: router.parameters,
                encoding: router.encoding,
                headers: router.httpHeaders
            )
            .validate(statusCode: 200..<300)
            .serializingDecodable(model)
            .value
        } catch let error as AFError {
            throw mapError(error)
        }
    }
    
    /// Alamofire 에러를 NetworkError로 매핑
    /// 분기 순서: 취소 → 연결 실패 → HTTP 상태 코드 → 디코딩 → 알 수 없는 오류
    private func mapError(_ error: AFError) -> NetworkError {
        
        // 요청 취소 (화면 이탈 등으로 Combine cancel 호출 시)
        if error.isExplicitlyCancelledError {
            return .requestCancelled
        }
        
        // 네트워크 연결 에러 (요청이 서버에 도달하지 못함)
        if case .sessionTaskFailed(let underlyingError) = error,
           let urlError = underlyingError as? URLError {
            switch urlError.code {
            case .notConnectedToInternet,
                 .networkConnectionLost,
                 .cannotFindHost,
                 .cannotConnectToHost,
                 .dnsLookupFailed:
                return .networkDisconnected
            case .timedOut:
                return .timeout
            case .secureConnectionFailed,
                 .serverCertificateUntrusted,
                 .clientCertificateRejected:
                return .sslError
            default:
                return .unknownError
            }
        }
        
        // HTTP 상태 코드 에러 (서버 응답은 받았으나 실패)
        if case .responseValidationFailed(let reason) = error {
            if case .unacceptableStatusCode(let statusCode) = reason {
                switch statusCode {
                case 400:
                    return .badRequest
                case 401:
                    return .unauthorized
                case 403:
                    return .forbidden
                case 404:
                    return .notFound
                case 500...599:
                    return .serverError
                default:
                    return .unknownError
                }
            }
        }
        
        // 디코딩 에러 (서버 응답은 성공했으나 디코딩 실패)
        if error.isResponseSerializationError {
            return .decodingFailed
        }
        
        return .unknownError
    }
}

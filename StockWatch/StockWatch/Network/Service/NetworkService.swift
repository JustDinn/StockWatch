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
        print("<< [NetworkService] request called - URL: \(router.urlString), method: \(router.method)")
        do {
            let result = try await AF.request(
                router.urlString,
                method: router.method,
                parameters: router.parameters,
                encoding: router.encoding,
                headers: router.httpHeaders
            )
            .validate(statusCode: 200..<300)
            .serializingDecodable(model)
            .value
            print("<< [NetworkService] request succeeded - model: \(T.self)")
            return result
        } catch let error as AFError {
            print("<< [NetworkService] AFError caught - will mapError: \(error)")
            let mappedError = mapError(error)
            print("<< [NetworkService] mapped to NetworkError: \(mappedError)")
            throw mappedError
        }
    }

    /// Alamofire 에러를 NetworkError로 매핑
    /// 분기 순서: 취소 → 연결 실패 → HTTP 상태 코드 → 디코딩 → 알 수 없는 오류
    private func mapError(_ error: AFError) -> NetworkError {
        print("<< [NetworkService] mapError - isExplicitlyCancelled: \(error.isExplicitlyCancelledError), isSessionTaskFailed: \(error.isSessionTaskError), isResponseValidationFailed: \(error.isResponseValidationError), isResponseSerializationError: \(error.isResponseSerializationError)")

        // 요청 취소 (화면 이탈 등으로 Combine cancel 호출 시)
        if error.isExplicitlyCancelledError {
            print("<< [NetworkService] mapError -> .requestCancelled")
            return .requestCancelled
        }

        // 네트워크 연결 에러 (요청이 서버에 도달하지 못함)
        if case .sessionTaskFailed(let underlyingError) = error,
           let urlError = underlyingError as? URLError {
            print("<< [NetworkService] mapError sessionTaskFailed - URLError code: \(urlError.code)")
            switch urlError.code {
            case .notConnectedToInternet,
                 .networkConnectionLost,
                 .cannotFindHost,
                 .cannotConnectToHost,
                 .dnsLookupFailed:
                print("<< [NetworkService] mapError -> .networkDisconnected")
                return .networkDisconnected
            case .timedOut:
                print("<< [NetworkService] mapError -> .timeout")
                return .timeout
            case .secureConnectionFailed,
                 .serverCertificateUntrusted,
                 .clientCertificateRejected:
                print("<< [NetworkService] mapError -> .sslError")
                return .sslError
            default:
                print("<< [NetworkService] mapError -> .unknownError (URLError default)")
                return .unknownError
            }
        }

        // HTTP 상태 코드 에러 (서버 응답은 받았으나 실패)
        if case .responseValidationFailed(let reason) = error {
            if case .unacceptableStatusCode(let statusCode) = reason {
                print("<< [NetworkService] mapError responseValidationFailed - statusCode: \(statusCode)")
                switch statusCode {
                case 400:
                    return .badRequest
                case 401:
                    return .unauthorized
                case 403:
                    return .forbidden
                case 404:
                    return .notFound
                case 429:
                    return .rateLimitExceeded
                case 500...599:
                    return .serverError
                default:
                    print("<< [NetworkService] mapError -> .unknownError (statusCode: \(statusCode))")
                    return .unknownError
                }
            }
        }

        // 디코딩 에러 (서버 응답은 성공했으나 디코딩 실패)
        if error.isResponseSerializationError {
            print("<< [NetworkService] mapError -> .decodingFailed")
            return .decodingFailed
        }

        print("<< [NetworkService] mapError -> .unknownError (fallthrough)")
        return .unknownError
    }
}

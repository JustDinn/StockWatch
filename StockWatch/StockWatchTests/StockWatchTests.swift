//
//  StockWatchTests.swift
//  StockWatchTests
//
//  Created by HyoTaek on 2/22/26.
//

import XCTest
import Alamofire
@testable import StockWatch

// MARK: - Finnhub 주식 현재가 Router (Integration Test 전용)

private struct FinnhubQuoteRouter: NetworkRouter {
    let symbol: String
    let apiKey: String
    
    var apiService: APIService { .finnhub }
    var path: String { "/quote" }
    var method: HTTPMethod { .get }
    var parameters: [String: Any]? {
        ["symbol": symbol, "token": apiKey]
    }
    var headers: [String: String]? { nil }
}

// MARK: - Finnhub 주식 현재가 Response 모델 (Integration Test 전용)

private struct FinnhubQuoteResponse: Decodable {
    /// 현재가 (Current price)
    let c: Double
    /// 전일 대비 변동액 (Change) - 거래 없을 시 null
    let d: Double?
    /// 전일 대비 변동률 (Percent change) - 거래 없을 시 null
    let dp: Double?
    /// 고가 (High price of the day)
    let h: Double
    /// 저가 (Low price of the day)
    let l: Double
    /// 시가 (Open price of the day)
    let o: Double
    /// 전일 종가 (Previous close price)
    let pc: Double
}

// MARK: - NetworkService Integration Tests

final class NetworkServiceIntegrationTests: XCTestCase {

    private var apiKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "FINNHUB_API_KEY") as? String else {
            fatalError("[통합 Test] Info.plist에서 FINNHUB_API_KEY를 찾을 수 없습니다. Secrets.xcconfig를 확인해주세요.")
        }
        return key
    }

    // MARK: - Tests

    /// 유효한 티커의 현재가 조회로 NetworkService.request 동작 검증
    func testFetchValidTickerPrice() async throws {
        let response = try await fetchQuote(symbol: "AAPL")

        XCTAssertGreaterThan(response.c, 0, "[통합 Test] 현재가는 0보다 커야 합니다.")
        
        print("[통합 Test] 현재가: $\(response.c)")
        print("[통합 Test] 전일 종가: $\(response.pc)")
        print("[통합 Test] 변동: \(response.d.map { "\($0)" } ?? "-") (\(response.dp.map { "\($0)" } ?? "-")%)")
    }

    /// 잘못된 티커 입력 시 현재가 0 확인
    func testFetchInvalidTickerPrice() async throws {
        let response = try await fetchQuote(symbol: "INVALIDSYMBOL999")
        
        // Finnhub는 알 수 없는 심볼에 대해 모든 필드가 0인 응답을 반환함
        XCTAssertEqual(response.c, 0, "[통합 Test] 잘못된 티커의 현재가는 0이어야 합니다.")
    }

    // MARK: - Helpers

    private func fetchQuote(symbol: String) async throws -> FinnhubQuoteResponse {
        let service = NetworkService()
        let router = FinnhubQuoteRouter(symbol: symbol, apiKey: apiKey)
        return try await service.request(router: router, model: FinnhubQuoteResponse.self)
    }
}

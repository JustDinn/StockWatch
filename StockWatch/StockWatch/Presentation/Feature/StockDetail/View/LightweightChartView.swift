//
//  LightweightChartView.swift
//  StockWatch
//

import SwiftUI
import WebKit

struct LightweightChartView: UIViewRepresentable {

    let candles: [Candle]
    var olderCandles: [Candle]? = nil
    /// MA 계산 전용 캔들 (warmup 포함). nil이면 candles로 계산
    var maCalculationCandles: [Candle]? = nil
    var maConfiguration: MAIndicatorConfiguration? = nil
    var isMAEnabled: Bool = false
    var onReachedLeftEdge: (() -> Void)? = nil
    var onOlderDataInjected: (() -> Void)? = nil

    @AppStorage("candle_body_up_color_hex") private var bodyUpColorHex: String = "#ef5350"
    @AppStorage("candle_body_down_color_hex") private var bodyDownColorHex: String = "#1976d2"
    @AppStorage("candle_border_up_color_hex") private var borderUpColorHex: String = "#ef5350"
    @AppStorage("candle_border_down_color_hex") private var borderDownColorHex: String = "#1976d2"
    @AppStorage("candle_wick_up_color_hex") private var wickUpColorHex: String = "#ef5350"
    @AppStorage("candle_wick_down_color_hex") private var wickDownColorHex: String = "#1976d2"

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true

        let weakHandler = WeakScriptMessageHandler(handler: context.coordinator)
        config.userContentController.add(weakHandler, name: "chartEdge")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView
        context.coordinator.onReachedLeftEdge = onReachedLeftEdge

        if let url = Bundle.main.url(forResource: "chart", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.onReachedLeftEdge = onReachedLeftEdge
        context.coordinator.onOlderDataInjected = onOlderDataInjected
        context.coordinator.bodyUpColorHex = bodyUpColorHex
        context.coordinator.bodyDownColorHex = bodyDownColorHex
        context.coordinator.borderUpColorHex = borderUpColorHex
        context.coordinator.borderDownColorHex = borderDownColorHex
        context.coordinator.wickUpColorHex = wickUpColorHex
        context.coordinator.wickDownColorHex = wickDownColorHex

        if context.coordinator.isLoaded {
            context.coordinator.injectColors(into: webView)
            if let older = olderCandles {
                context.coordinator.injectOlderData(older, into: webView)
                context.coordinator.lastInjectedDataID = context.coordinator.dataID(for: candles)
            } else {
                let newID = context.coordinator.dataID(for: candles)
                if newID != context.coordinator.lastInjectedDataID {
                    context.coordinator.injectData(candles, into: webView)
                    context.coordinator.lastInjectedDataID = newID
                }
            }

            // 이동평균선 주입
            if isMAEnabled, let config = maConfiguration {
                context.coordinator.injectMovingAverages(
                    candles: candles,
                    maCalculationCandles: maCalculationCandles,
                    configuration: config,
                    into: webView
                )
            } else {
                context.coordinator.clearMovingAverages(into: webView)
            }
        } else {
            context.coordinator.pendingCandles = candles
            context.coordinator.pendingIsMAEnabled = isMAEnabled
            context.coordinator.pendingMAConfiguration = maConfiguration
            context.coordinator.pendingMACalculationCandles = maCalculationCandles
        }
    }
}

// MARK: - WeakScriptMessageHandler

final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var handler: WKScriptMessageHandler?

    init(handler: WKScriptMessageHandler) {
        self.handler = handler
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        handler?.userContentController(userContentController, didReceive: message)
    }
}

// MARK: - Coordinator

extension LightweightChartView {

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var webView: WKWebView?
        var pendingCandles: [Candle] = []
        var pendingIsMAEnabled: Bool = false
        var pendingMAConfiguration: MAIndicatorConfiguration? = nil
        var pendingMACalculationCandles: [Candle]? = nil
        var isLoaded = false
        var onReachedLeftEdge: (() -> Void)?
        var onOlderDataInjected: (() -> Void)?
        var lastInjectedDataID: String?
        var bodyUpColorHex: String = "#ef5350"
        var bodyDownColorHex: String = "#1976d2"
        var borderUpColorHex: String = "#ef5350"
        var borderDownColorHex: String = "#1976d2"
        var wickUpColorHex: String = "#ef5350"
        var wickDownColorHex: String = "#1976d2"

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoaded = true
            injectColors(into: webView)
            injectData(pendingCandles, into: webView)
            lastInjectedDataID = dataID(for: pendingCandles)
            if pendingIsMAEnabled, let config = pendingMAConfiguration {
                injectMovingAverages(candles: pendingCandles, maCalculationCandles: pendingMACalculationCandles, configuration: config, into: webView)
            }
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "chartEdge",
                  let body = message.body as? String,
                  body == "reachedLeftEdge" else { return }
            DispatchQueue.main.async { [weak self] in
                self?.onReachedLeftEdge?()
            }
        }

        func injectColors(into webView: WKWebView) {
            let js = "setColors('\(bodyUpColorHex)', '\(bodyDownColorHex)', '\(borderUpColorHex)', '\(borderDownColorHex)', '\(wickUpColorHex)', '\(wickDownColorHex)')"
            webView.evaluateJavaScript(js, completionHandler: nil)
        }

        func injectData(_ candles: [Candle], into webView: WKWebView) {
            guard !candles.isEmpty else { return }
            let jsData = buildJSArray(candles)
            let js = "setData('[\(jsData)]')"
            webView.evaluateJavaScript(js, completionHandler: nil)
        }

        func injectOlderData(_ candles: [Candle], into webView: WKWebView) {
            guard !candles.isEmpty else { return }
            let jsData = buildJSArray(candles)
            let js = "appendOlderData('[\(jsData)]')"
            webView.evaluateJavaScript(js) { [weak self] _, _ in
                DispatchQueue.main.async {
                    self?.onOlderDataInjected?()
                }
            }
        }

        func dataID(for candles: [Candle]) -> String {
            guard let first = candles.first, let last = candles.last else { return "" }
            return "\(candles.count)_\(Int(first.timestamp.timeIntervalSince1970))_\(Int(last.timestamp.timeIntervalSince1970))"
        }

        func injectMovingAverages(
            candles: [Candle],
            maCalculationCandles: [Candle]?,
            configuration: MAIndicatorConfiguration,
            into webView: WKWebView
        ) {
            let calcCandles = maCalculationCandles ?? candles
            print("<< [InjectMA] calcCandles 소스=\(maCalculationCandles != nil ? "maCalculationCandles" : "candles") calcCandles.count=\(calcCandles.count) displayCandles.count=\(candles.count)")
            guard !candles.isEmpty, !configuration.lines.isEmpty else {
                clearMovingAverages(into: webView)
                return
            }

            var maLines: [[String: Any]] = []

            for line in configuration.lines {
                let smaData = TechnicalIndicatorCalculator.smaTimeSeries(
                    candles: calcCandles,
                    period: line.period
                )
                let displayStart = candles.first?.timestamp ?? Date.distantPast
                let filteredSmaData = smaData.filter { $0.timestamp >= displayStart }
                print("<< [InjectMA] period=\(line.period) smaData.count=\(smaData.count) displayStart=\(displayStart) filteredSmaData.count=\(filteredSmaData.count)")
                guard !filteredSmaData.isEmpty else { continue }

                let jsData = filteredSmaData.map { item in
                    [
                        "time": Int(item.timestamp.timeIntervalSince1970),
                        "value": item.value
                    ] as [String: Any]
                }

                maLines.append([
                    "period": line.period,
                    "color": line.colorHex,
                    "lineWidth": line.lineWidth,
                    "data": jsData
                ])
            }

            guard !maLines.isEmpty else {
                clearMovingAverages(into: webView)
                return
            }

            // Convert to JSON
            if let jsonData = try? JSONSerialization.data(withJSONObject: maLines),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                let js = "setMovingAverages('\(jsonString.replacingOccurrences(of: "'", with: "\\'"))')"
                webView.evaluateJavaScript(js, completionHandler: nil)
            }
        }

        func clearMovingAverages(into webView: WKWebView) {
            let js = "clearMovingAverages()"
            webView.evaluateJavaScript(js, completionHandler: nil)
        }

        private func buildJSArray(_ candles: [Candle]) -> String {
            candles.map { c in
                let time = Int(c.timestamp.timeIntervalSince1970)
                return "{\"time\":\(time),\"open\":\(c.open),\"high\":\(c.high),\"low\":\(c.low),\"close\":\(c.close)}"
            }.joined(separator: ",")
        }
    }
}

//
//  LightweightChartView.swift
//  StockWatch
//

import SwiftUI
import WebKit

struct LightweightChartView: UIViewRepresentable {

    let candles: [Candle]

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

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView

        if let url = Bundle.main.url(forResource: "chart", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.pendingCandles = candles
        context.coordinator.bodyUpColorHex = bodyUpColorHex
        context.coordinator.bodyDownColorHex = bodyDownColorHex
        context.coordinator.borderUpColorHex = borderUpColorHex
        context.coordinator.borderDownColorHex = borderDownColorHex
        context.coordinator.wickUpColorHex = wickUpColorHex
        context.coordinator.wickDownColorHex = wickDownColorHex
        if context.coordinator.isLoaded {
            context.coordinator.injectColors(into: webView)
            context.coordinator.injectData(candles, into: webView)
        }
    }
}

// MARK: - Coordinator

extension LightweightChartView {

    final class Coordinator: NSObject, WKNavigationDelegate {
        var webView: WKWebView?
        var pendingCandles: [Candle] = []
        var isLoaded = false
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
        }

        func injectColors(into webView: WKWebView) {
            let js = "setColors('\(bodyUpColorHex)', '\(bodyDownColorHex)', '\(borderUpColorHex)', '\(borderDownColorHex)', '\(wickUpColorHex)', '\(wickDownColorHex)')"
            webView.evaluateJavaScript(js, completionHandler: nil)
        }

        func injectData(_ candles: [Candle], into webView: WKWebView) {
            guard !candles.isEmpty else { return }

            let jsData = candles.map { c in
                let time = Int(c.timestamp.timeIntervalSince1970)
                return "{\"time\":\(time),\"open\":\(c.open),\"high\":\(c.high),\"low\":\(c.low),\"close\":\(c.close)}"
            }.joined(separator: ",")

            let js = "setData('[\(jsData)]')"
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }
}

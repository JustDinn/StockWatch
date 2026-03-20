//
//  LightweightChartView.swift
//  StockWatch
//

import SwiftUI
import WebKit

struct LightweightChartView: UIViewRepresentable {

    let candles: [Candle]
    var olderCandles: [Candle]? = nil
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
        } else {
            context.coordinator.pendingCandles = candles
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

        private func buildJSArray(_ candles: [Candle]) -> String {
            candles.map { c in
                let time = Int(c.timestamp.timeIntervalSince1970)
                return "{\"time\":\(time),\"open\":\(c.open),\"high\":\(c.high),\"low\":\(c.low),\"close\":\(c.close)}"
            }.joined(separator: ",")
        }
    }
}

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
    var isVolumeEnabled: Bool = false
    var volumeMAConfiguration: VolumeMAConfiguration? = nil
    var isRSIEnabled: Bool = false
    var rsiConfiguration: RSIConfiguration? = nil
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
                // olderCandles가 있을 때는 appendOlderData 완료 후 MA/Volume/RSI 주입 (타이밍 보장)
                let maEnabled = isMAEnabled
                let maConfig = maConfiguration
                let maCalcCandles = maCalculationCandles
                let displayCandles = candles
                let volumeEnabled = isVolumeEnabled
                let volumeMAConfig = volumeMAConfiguration
                let rsiEnabled = isRSIEnabled
                let rsiConfig = rsiConfiguration
                context.coordinator.injectOlderData(older, into: webView) { [weak coordinator = context.coordinator] in
                    guard let coordinator, let webView = coordinator.webView else { return }
                    if maEnabled, let config = maConfig {
                        coordinator.injectMovingAverages(
                            candles: displayCandles,
                            maCalculationCandles: maCalcCandles,
                            configuration: config,
                            into: webView
                        )
                    } else {
                        coordinator.clearMovingAverages(into: webView)
                    }
                    if volumeEnabled {
                        coordinator.injectOlderVolumeData(older, into: webView)
                        if let volumeMAConfig {
                            coordinator.injectVolumeMA(candles: displayCandles, maCalculationCandles: nil, configuration: volumeMAConfig, into: webView)
                        }
                    }
                    if rsiEnabled, let config = rsiConfig {
                        coordinator.injectRSI(
                            candles: displayCandles,
                            maCalculationCandles: maCalcCandles,
                            configuration: config,
                            isVolumeEnabled: volumeEnabled,
                            into: webView
                        )
                    } else {
                        coordinator.clearRSI(into: webView)
                    }
                }
                context.coordinator.lastInjectedDataID = context.coordinator.dataID(for: candles)
            } else {
                let newID = context.coordinator.dataID(for: candles)
                if newID != context.coordinator.lastInjectedDataID {
                    // 새 캔들 데이터가 있을 때: setData() 완료 후 MA/Volume/RSI 주입 (타이밍 보장)
                    context.coordinator.lastInjectedDataID = newID
                    let maEnabled = isMAEnabled
                    let maConfig = maConfiguration
                    let maCalcCandles = maCalculationCandles
                    let volumeEnabled = isVolumeEnabled
                    let volumeMAConfig = volumeMAConfiguration
                    let rsiEnabled = isRSIEnabled
                    let rsiConfig = rsiConfiguration
                    context.coordinator.injectData(candles, into: webView) { [weak coordinator = context.coordinator] in
                        guard let coordinator, let webView = coordinator.webView else { return }

                        if maEnabled, let config = maConfig {
                            coordinator.injectMovingAverages(
                                candles: candles,
                                maCalculationCandles: maCalcCandles,
                                configuration: config,
                                into: webView
                            )
                        } else {
                            coordinator.clearMovingAverages(into: webView)
                        }
                        if volumeEnabled {
                            coordinator.injectVolumeData(candles, into: webView) { [weak coordinator] in
                                guard let coordinator, let webView = coordinator.webView else { return }
                                if let volumeMAConfig {
                                    coordinator.injectVolumeMA(candles: candles, maCalculationCandles: maCalcCandles, configuration: volumeMAConfig, into: webView)
                                }
                            }
                        } else {
                            coordinator.clearVolume(into: webView)
                            coordinator.clearVolumeMA(into: webView)
                        }
                        if rsiEnabled, let config = rsiConfig {
                            coordinator.injectRSI(
                                candles: candles,
                                maCalculationCandles: maCalcCandles,
                                configuration: config,
                                isVolumeEnabled: volumeEnabled,
                                into: webView
                            )
                        } else {
                            coordinator.clearRSI(into: webView)
                        }
                    }
                } else {
                    // dataID 변경 없음 (설정만 바뀐 경우): setData() 재호출 없으므로 즉시 주입
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
                    if isVolumeEnabled {
                        context.coordinator.injectVolumeData(candles, into: webView) { [weak coordinator = context.coordinator] in
                            guard let coordinator, let webView = coordinator.webView else { return }
                            if let volumeMAConfiguration {
                                coordinator.injectVolumeMA(candles: candles, maCalculationCandles: maCalculationCandles, configuration: volumeMAConfiguration, into: webView)
                            }
                        }
                    } else {
                        context.coordinator.clearVolume(into: webView)
                        context.coordinator.clearVolumeMA(into: webView)
                    }
                    if isRSIEnabled, let config = rsiConfiguration {
                        context.coordinator.injectRSI(
                            candles: candles,
                            maCalculationCandles: maCalculationCandles,
                            configuration: config,
                            isVolumeEnabled: isVolumeEnabled,
                            into: webView
                        )
                    } else {
                        context.coordinator.clearRSI(into: webView)
                    }
                }
            }
        } else {
            context.coordinator.pendingCandles = candles
            context.coordinator.pendingIsMAEnabled = isMAEnabled
            context.coordinator.pendingMAConfiguration = maConfiguration
            context.coordinator.pendingMACalculationCandles = maCalculationCandles
            context.coordinator.pendingIsVolumeEnabled = isVolumeEnabled
            context.coordinator.pendingVolumeMAConfiguration = volumeMAConfiguration
            context.coordinator.pendingIsRSIEnabled = isRSIEnabled
            context.coordinator.pendingRSIConfiguration = rsiConfiguration
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
        var pendingIsVolumeEnabled: Bool = false
        var pendingVolumeMAConfiguration: VolumeMAConfiguration? = nil
        var pendingIsRSIEnabled: Bool = false
        var pendingRSIConfiguration: RSIConfiguration? = nil
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
            lastInjectedDataID = dataID(for: pendingCandles)
            injectData(pendingCandles, into: webView) { [weak self] in
                guard let self, let webView = self.webView else { return }

                if self.pendingIsMAEnabled, let config = self.pendingMAConfiguration {
                    self.injectMovingAverages(
                        candles: self.pendingCandles,
                        maCalculationCandles: self.pendingMACalculationCandles,
                        configuration: config,
                        into: webView
                    )
                }
                if self.pendingIsVolumeEnabled {
                    self.injectVolumeData(self.pendingCandles, into: webView) { [weak self] in
                        guard let self, let webView = self.webView else { return }
                        if let config = self.pendingVolumeMAConfiguration {
                            self.injectVolumeMA(candles: self.pendingCandles, maCalculationCandles: self.pendingMACalculationCandles, configuration: config, into: webView)
                        }
                    }
                }
                if self.pendingIsRSIEnabled, let config = self.pendingRSIConfiguration {
                    self.injectRSI(
                        candles: self.pendingCandles,
                        maCalculationCandles: self.pendingMACalculationCandles,
                        configuration: config,
                        isVolumeEnabled: self.pendingIsVolumeEnabled,
                        into: webView
                    )
                }
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

        func injectData(_ candles: [Candle], into webView: WKWebView, completion: (() -> Void)? = nil) {
            guard !candles.isEmpty else {
                completion?()
                return
            }
            let jsData = buildJSArray(candles)
            let js = "setData('[\(jsData)]')"
            webView.evaluateJavaScript(js) { _, _ in
                DispatchQueue.main.async {
                    completion?()
                }
            }
        }

        func injectOlderData(_ candles: [Candle], into webView: WKWebView, completion: (() -> Void)? = nil) {
            guard !candles.isEmpty else {
                completion?()
                return
            }
            let jsData = buildJSArray(candles)
            let js = "appendOlderData('[\(jsData)]')"
            webView.evaluateJavaScript(js) { [weak self] _, _ in
                DispatchQueue.main.async {
                    self?.onOlderDataInjected?()
                    completion?()
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
            guard !candles.isEmpty, !configuration.lines.isEmpty else {
                clearMovingAverages(into: webView)
                return
            }

            var maLines: [[String: Any]] = []

            for line in configuration.lines {
                let smaData = TechnicalIndicatorCalculator.smaTimeSeries(
                    candles: calcCandles,
                    period: line.period,
                    priceSource: line.priceSource
                )
                let displayStart = candles.first?.timestamp ?? Date.distantPast
                let filteredSmaData = smaData.filter { $0.timestamp >= displayStart }
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

        func injectVolumeData(_ candles: [Candle], into webView: WKWebView, completion: (() -> Void)? = nil) {
            guard !candles.isEmpty else { completion?(); return }
            let jsData = buildVolumeJSArray(candles)
            let js = "setVolumeData('[\(jsData)]')"
            webView.evaluateJavaScript(js) { _, _ in
                DispatchQueue.main.async {
                    completion?()
                }
            }
        }

        func injectOlderVolumeData(_ candles: [Candle], into webView: WKWebView) {
            guard !candles.isEmpty else { return }
            let jsData = buildVolumeJSArray(candles)
            let js = "appendOlderVolumeData('[\(jsData)]')"
            webView.evaluateJavaScript(js, completionHandler: nil)
        }

        func clearVolume(into webView: WKWebView) {
            let js = "clearVolume()"
            webView.evaluateJavaScript(js, completionHandler: nil)
        }

        func injectVolumeMA(
            candles: [Candle],
            maCalculationCandles: [Candle]?,
            configuration: VolumeMAConfiguration,
            into webView: WKWebView
        ) {
            let line = configuration.line
            guard line.isEnabled, !candles.isEmpty else {
                clearVolumeMA(into: webView)
                return
            }

            let calcCandles = maCalculationCandles ?? candles
            let smaData = TechnicalIndicatorCalculator.volumeSmaTimeSeries(candles: calcCandles, period: line.period)
            let displayStart = candles.first?.timestamp ?? Date.distantPast
            let filteredSmaData = smaData.filter { $0.timestamp >= displayStart }
            guard !filteredSmaData.isEmpty else {
                clearVolumeMA(into: webView)
                return
            }

            let jsData = filteredSmaData.map { item in
                ["time": Int(item.timestamp.timeIntervalSince1970), "value": item.value] as [String: Any]
            }

            let payload: [String: Any] = [
                "color": line.colorHex,
                "lineWidth": line.lineWidth,
                "data": jsData
            ]

            if let jsonData = try? JSONSerialization.data(withJSONObject: payload),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                let js = "setVolumeMA('\(jsonString.replacingOccurrences(of: "'", with: "\\'"))')"
                webView.evaluateJavaScript(js, completionHandler: nil)
            }
        }

        func clearVolumeMA(into webView: WKWebView) {
            let js = "clearVolumeMA()"
            webView.evaluateJavaScript(js, completionHandler: nil)
        }

        func injectRSI(
            candles: [Candle],
            maCalculationCandles: [Candle]?,
            configuration: RSIConfiguration,
            isVolumeEnabled: Bool,
            into webView: WKWebView
        ) {
            guard configuration.line.isEnabled, !candles.isEmpty else {
                clearRSI(into: webView)
                return
            }

            let calcCandles = maCalculationCandles ?? candles
            let rsiData = TechnicalIndicatorCalculator.rsiTimeSeries(
                candles: calcCandles,
                period: configuration.line.period
            )
            let displayStart = candles.first?.timestamp ?? Date.distantPast
            let filteredData = rsiData.filter { $0.timestamp >= displayStart }
            guard !filteredData.isEmpty else {
                clearRSI(into: webView)
                return
            }

            let jsData = filteredData.map { item in
                ["time": Int(item.timestamp.timeIntervalSince1970), "value": item.value] as [String: Any]
            }

            let payload: [String: Any] = [
                "data": jsData,
                "lineColor": configuration.line.colorHex,
                "lineWidth": configuration.line.lineWidth,
                "upperEnabled": configuration.upperLevel.isEnabled,
                "upperValue": configuration.upperLevel.value,
                "middleEnabled": configuration.middleLevel.isEnabled,
                "middleValue": configuration.middleLevel.value,
                "lowerEnabled": configuration.lowerLevel.isEnabled,
                "lowerValue": configuration.lowerLevel.value,
                "bgEnabled": configuration.background.isEnabled,
                "bgColor": configuration.background.colorHex,
                "volumeEnabled": isVolumeEnabled
            ]

            if let jsonData = try? JSONSerialization.data(withJSONObject: payload),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                let js = "setRSIData('\(jsonString.replacingOccurrences(of: "'", with: "\\'"))')"
                webView.evaluateJavaScript(js, completionHandler: nil)
            }
        }

        func clearRSI(into webView: WKWebView) {
            let js = "clearRSI()"
            webView.evaluateJavaScript(js, completionHandler: nil)
        }

        private func buildJSArray(_ candles: [Candle]) -> String {
            candles.map { c in
                let time = Int(c.timestamp.timeIntervalSince1970)
                return "{\"time\":\(time),\"open\":\(c.open),\"high\":\(c.high),\"low\":\(c.low),\"close\":\(c.close)}"
            }.joined(separator: ",")
        }

        private func buildVolumeJSArray(_ candles: [Candle]) -> String {
            candles.map { c in
                let time = Int(c.timestamp.timeIntervalSince1970)
                let color = c.close >= c.open ? bodyUpColorHex : bodyDownColorHex
                return "{\"time\":\(time),\"value\":\(c.volume),\"color\":\"\(color)\"}"
            }.joined(separator: ",")
        }
    }
}

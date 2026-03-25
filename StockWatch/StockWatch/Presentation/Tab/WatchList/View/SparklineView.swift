//
//  SparklineView.swift
//  StockWatch
//

import SwiftUI

/// 종가 데이터를 선 + 그라데이션으로 표시하는 스파크라인 차트
struct SparklineView: View {
    let closePrices: [Double]
    let isPositive: Bool
    var currentPrice: Double? = nil

    private var lineColor: Color {
        isPositive ? Color(hex: "#ef5350") : Color(hex: "#1976d2")
    }

    var body: some View {
        GeometryReader { geo in
            let points = normalizedPoints(in: geo.size)
            if points.count >= 2 {
                ZStack {
                    // 그라데이션 채움
                    fillPath(points: points, height: geo.size.height)
                        .fill(
                            LinearGradient(
                                colors: [lineColor.opacity(0.3), lineColor.opacity(0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    // 현재가 수평 점선
                    if let price = currentPrice {
                        let y = currentPriceY(price: price, height: geo.size.height)
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: geo.size.width, y: y))
                        }
                        .stroke(lineColor.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                    }
                    // 선
                    linePath(points: points)
                        .stroke(lineColor, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                }
            }
        }
    }

    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        guard closePrices.count >= 2 else { return [] }
        let minVal = closePrices.min() ?? 0
        let maxVal = closePrices.max() ?? 1
        let range = maxVal - minVal
        let safeRange = range == 0 ? 1.0 : range
        let stepX = size.width / CGFloat(closePrices.count - 1)

        return closePrices.enumerated().map { index, price in
            let x = CGFloat(index) * stepX
            let y = size.height - (CGFloat((price - minVal) / safeRange) * size.height)
            return CGPoint(x: x, y: y)
        }
    }

    private func currentPriceY(price: Double, height: CGFloat) -> CGFloat {
        let minVal = closePrices.min() ?? 0
        let maxVal = closePrices.max() ?? 1
        let range = maxVal - minVal
        let safeRange = range == 0 ? 1.0 : range
        let normalized = (price - minVal) / safeRange
        let y = height - CGFloat(normalized) * height
        return min(max(y, 0), height)
    }

    private func linePath(points: [CGPoint]) -> Path {
        Path { path in
            path.move(to: points[0])
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }
    }

    private func fillPath(points: [CGPoint], height: CGFloat) -> Path {
        Path { path in
            path.move(to: points[0])
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
            // 아래로 닫기
            if let last = points.last {
                path.addLine(to: CGPoint(x: last.x, y: height))
            }
            path.addLine(to: CGPoint(x: points[0].x, y: height))
            path.closeSubpath()
        }
    }
}

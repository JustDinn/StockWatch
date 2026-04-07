//
//  UIFont++Extension.swift
//  Crescendo
//
//  Created by HyoTaek on 10/1/25.
//

import SwiftUI
import PretendardKit

extension Font {

    static func pretendardBold(size: CGFloat) -> Font {
        Font(UIFont.pretendard(ofSize: size, weight: .bold))
    }

    static func pretendardSemibold(size: CGFloat) -> Font {
        Font(UIFont.pretendard(ofSize: size, weight: .semibold))
    }

    static func pretendardMedium(size: CGFloat) -> Font {
        Font(UIFont.pretendard(ofSize: size, weight: .medium))
    }

    static func pretendardLight(size: CGFloat) -> Font {
        Font(UIFont.pretendard(ofSize: size, weight: .light))
    }

    static func pretendard(size: CGFloat) -> Font {
        Font(UIFont.pretendard(ofSize: size, weight: .regular))
    }

    // MARK: - Semantic Aliases

    static let pretendardLargeTitle  = Font.pretendardBold(size: 34)
    static let pretendardTitle       = Font.pretendardBold(size: 28)
    static let pretendardTitle2      = Font.pretendardBold(size: 22)
    static let pretendardTitle3      = Font.pretendardSemibold(size: 20)
    static let pretendardHeadline    = Font.pretendardBold(size: 17)
    static let pretendardBody        = Font.pretendard(size: 17)
    static let pretendardSubheadline = Font.pretendard(size: 15)
    static let pretendardFootnote    = Font.pretendard(size: 13)
    static let pretendardCaption     = Font.pretendard(size: 12)
    static let pretendardCaption2    = Font.pretendard(size: 11)
}

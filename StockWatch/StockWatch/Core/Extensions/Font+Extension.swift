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
}

//
//  SpeakEasyLayout.swift
//  speakEasy
//

import SwiftUI

enum SpeakEasyLayout {
    
    static func readableContentWidth(
        containerWidth: CGFloat,
        horizontalInset: CGFloat = 32,
        maxWidthRegular: CGFloat,
        maxWidthCompact: CGFloat,
        horizontalSizeClass: UserInterfaceSizeClass?
    ) -> CGFloat {
        let cap = horizontalSizeClass == .regular ? maxWidthRegular : maxWidthCompact
        let w = containerWidth
        let safeWidth: CGFloat = (w.isFinite && w > 0) ? w : 375
        let available = max(0, safeWidth - horizontalInset)
        return max(1, min(available, cap))
    }
}

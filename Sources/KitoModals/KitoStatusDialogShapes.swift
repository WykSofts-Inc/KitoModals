//
//  KitoStatusDialogShapes.swift
//  KitoModals
//
//  Created by Wycliff on 4/20/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI

/// Hand-drawn checkmark and X paths — trimmed 0→1 to animate as a stroke
/// drawing itself in, rather than fading in a static SF Symbol.
struct KitoCheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.20, y: rect.minY + rect.height * 0.52))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.42, y: rect.minY + rect.height * 0.74))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.82, y: rect.minY + rect.height * 0.26))
        return path
    }
}

struct KitoXmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.26, y: rect.minY + rect.height * 0.26))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.74, y: rect.minY + rect.height * 0.74))
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.74, y: rect.minY + rect.height * 0.26))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.26, y: rect.minY + rect.height * 0.74))
        return path
    }
}

//
//  KitoSheet.swift
//  KitoModals
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// A height the sheet can rest at.
public enum KitoSheetDetent: Hashable, Sendable {
    /// Exactly as tall as its content.
    case fit
    /// A fraction of the screen's height.
    case fraction(CGFloat)
    /// A fixed height in points.
    case height(CGFloat)
    /// Nearly the full screen.
    case large
}

/// How the sheet sits on screen.
public enum KitoSheetStyle: Equatable, Sendable {
    /// Full width, rounded top corners, running under the home indicator.
    case attached
    /// A card inset from the edges and the bottom, rounded all round.
    case floating
    /// Attached, on a translucent material.
    case glass
}

public struct KitoSheetConfiguration: Sendable {
    public var detents: [KitoSheetDetent]
    public var style: KitoSheetStyle
    public var showsGrabber: Bool
    /// Tap outside to dismiss.
    public var dismissesOnBackdropTap: Bool
    /// Drag down past the lowest detent to dismiss.
    public var dismissesOnDrag: Bool
    public var backdropOpacity: Double
    /// Blurs what's behind while the sheet is up.
    public var blursBackdrop: Bool
    public var cornerRadius: CGFloat
    /// The sheet's fill; nil uses `theme.colors.surface`.
    public var background: Color?

    public init(detents: [KitoSheetDetent] = [.fit], style: KitoSheetStyle = .attached, showsGrabber: Bool = true,
                dismissesOnBackdropTap: Bool = true, dismissesOnDrag: Bool = true, backdropOpacity: Double = 0.4,
                blursBackdrop: Bool = false, cornerRadius: CGFloat = 32, background: Color? = nil) {
        self.detents = detents.isEmpty ? [.fit] : detents
        self.style = style
        self.showsGrabber = showsGrabber
        self.dismissesOnBackdropTap = dismissesOnBackdropTap
        self.dismissesOnDrag = dismissesOnDrag
        self.backdropOpacity = backdropOpacity
        self.blursBackdrop = blursBackdrop
        self.cornerRadius = cornerRadius
        self.background = background
    }

    public static let `default` = KitoSheetConfiguration()
}

public extension View {
    /// A custom bottom sheet drawn above this view: detents you drag between, rubber-banding past
    /// the top, drag-down and tap-outside to dismiss, and attached, floating or glass styles.
    /// Attach it to a full-screen container.
    func kitoSheet<SheetContent: View>(isPresented: Binding<Bool>, configuration: KitoSheetConfiguration = .default,
                                       @ViewBuilder content: @escaping () -> SheetContent) -> some View {
        modifier(KitoSheetModifier(isPresented: isPresented, configuration: configuration, sheet: content))
    }
}

struct KitoSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let configuration: KitoSheetConfiguration
    @ViewBuilder let sheet: () -> SheetContent

    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var detentIndex = 0
    @State private var drag: CGFloat = 0
    @State private var contentHeight: CGFloat = 0

    private var animation: Animation { reduceMotion ? .easeInOut(duration: 0.25) : .spring(response: 0.42, dampingFraction: 0.84) }

    func body(content: Content) -> some View {
        content
            .blur(radius: isPresented && configuration.blursBackdrop ? 6 : 0)
            .overlay {
                GeometryReader { proxy in
                    let insets = proxy.safeAreaInsets
                    let screenHeight = proxy.size.height + insets.top + insets.bottom
                    let heights = configuration.detents.map { Self.resolve($0, content: contentHeight, screen: screenHeight, topInset: insets.top, grabber: configuration.showsGrabber) }
                    let current = heights[min(detentIndex, heights.count - 1)]
                    let visibleHeight = Self.visibleHeight(current: current, tallest: heights.max() ?? current, drag: drag)

                    ZStack(alignment: .bottom) {
                        if isPresented {
                            Color.black.opacity(configuration.backdropOpacity * (1 - Double(min(max(drag, 0) / max(current, 1), 1))))
                                .ignoresSafeArea()
                                .onTapGesture { if configuration.dismissesOnBackdropTap { dismiss() } }
                                .transition(.opacity)
                                .accessibilityAddTraits(.isButton)
                                .accessibilityLabel("Dismiss")

                            sheetBody(height: visibleHeight, bottomInset: insets.bottom, heights: heights)
                                .transition(.move(edge: .bottom))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .ignoresSafeArea(edges: .bottom)
                }
            }
            .animation(animation, value: isPresented)
            .onChange(of: isPresented) { _, presented in if presented { detentIndex = 0; drag = 0 } }
    }

    @ViewBuilder
    private func sheetBody(height: CGFloat, bottomInset: CGFloat, heights: [CGFloat]) -> some View {
        let floating = configuration.style == .floating
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: configuration.cornerRadius, bottomLeadingRadius: floating ? configuration.cornerRadius : 0,
            bottomTrailingRadius: floating ? configuration.cornerRadius : 0, topTrailingRadius: configuration.cornerRadius, style: .continuous
        )
        VStack(spacing: 0) {
            if configuration.showsGrabber {
                Capsule().fill(theme.colors.onSurface.opacity(0.25)).frame(width: 40, height: 5).padding(.top, 10).padding(.bottom, 6)
                    .accessibilityHidden(true)
            }
            sheet()
                .fixedSize(horizontal: false, vertical: true)
                .background(GeometryReader { g in Color.clear.preference(key: KitoSheetContentHeightKey.self, value: g.size.height) })
                .frame(maxHeight: .infinity, alignment: .top)
        }
        .padding(.bottom, floating ? 0 : bottomInset)
        .frame(maxWidth: .infinity)
        .frame(height: height + (floating ? 0 : bottomInset), alignment: .top)
        .background {
            if configuration.style == .glass {
                shape.fill(.ultraThinMaterial)
            } else {
                shape.fill(configuration.background ?? theme.colors.surface)
            }
        }
        .clipShape(shape)
        .shadow(color: .black.opacity(0.2), radius: 24, y: -4)
        .padding(.horizontal, floating ? 10 : 0)
        .padding(.bottom, floating ? max(bottomInset, 10) : 0)
        .onPreferenceChange(KitoSheetContentHeightKey.self) { contentHeight = $0 }
        .gesture(
            DragGesture()
                .onChanged { drag = $0.translation.height }
                .onEnded { value in settle(translation: value.translation.height, predicted: value.predictedEndTranslation.height, heights: heights) }
        )
        .accessibilityElement(children: .contain)
        .accessibilityAction(.escape) { dismiss() }
    }

    private func settle(translation: CGFloat, predicted: CGFloat, heights: [CGFloat]) {
        let current = heights[min(detentIndex, heights.count - 1)]
        let target = current - predicted
        withAnimation(animation) {
            drag = 0
            if configuration.dismissesOnDrag, target < (heights.min() ?? current) * 0.55 {
                isPresented = false
                return
            }
            detentIndex = Self.nearestDetent(to: target, in: heights)
        }
    }

    private func dismiss() {
        withAnimation(animation) { isPresented = false }
    }

    // MARK: Maths

    /// A detent's height in points. `.fit` adds the grabber's room to the measured content.
    static func resolve(_ detent: KitoSheetDetent, content: CGFloat, screen: CGFloat, topInset: CGFloat, grabber: Bool) -> CGFloat {
        let largest = screen - topInset - 10
        let value: CGFloat
        switch detent {
        case .fit: value = content + (grabber ? 21 : 0) + 8
        case .fraction(let fraction): value = screen * min(max(fraction, 0.05), 1)
        case .height(let height): value = height
        case .large: value = largest
        }
        return min(max(value, 60), largest)
    }

    /// Dragging up past the tallest detent gets harder the further you go; `overshoot` is how far
    /// past (in points), and the result how far the sheet actually grows.
    static func rubberBand(_ overshoot: CGFloat, limit: CGFloat) -> CGFloat {
        guard overshoot > 0 else { return overshoot }
        return limit * 0.12 * (1 - 1 / (overshoot / (limit * 0.12) + 1))
    }

    /// The sheet's height mid-drag. Down (`drag` > 0) shrinks it one-for-one; up grows it
    /// one-for-one to the tallest detent, then rubber-bands.
    static func visibleHeight(current: CGFloat, tallest: CGFloat, drag: CGFloat) -> CGFloat {
        if drag >= 0 { return max(current - drag, 0) }
        let up = -drag
        let room = max(tallest - current, 0)
        return current + min(up, room) + rubberBand(max(up - room, 0), limit: tallest)
    }

    /// The index of the detent closest to `height`.
    static func nearestDetent(to height: CGFloat, in heights: [CGFloat]) -> Int {
        heights.enumerated().min { abs($0.element - height) < abs($1.element - height) }?.offset ?? 0
    }
}

struct KitoSheetContentHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

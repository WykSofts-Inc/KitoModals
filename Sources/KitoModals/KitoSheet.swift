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

/// How the sheet treats its content.
public enum KitoSheetContentMode: Equatable, Sendable {
    /// The content keeps its natural height and the whole sheet is draggable. Best for short
    /// content such as a confirmation or a picker.
    case fitted
    /// The content scrolls inside the sheet. The sheet drags from the grabber and header, or
    /// when the content is pulled down while already scrolled to the top. Use for long lists.
    case scrollable
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
    /// Fitted (default) or scrollable content.
    public var contentMode: KitoSheetContentMode

    public init(detents: [KitoSheetDetent] = [.fit], style: KitoSheetStyle = .attached, showsGrabber: Bool = true,
                dismissesOnBackdropTap: Bool = true, dismissesOnDrag: Bool = true, backdropOpacity: Double = 0.4,
                blursBackdrop: Bool = false, cornerRadius: CGFloat = 32, background: Color? = nil,
                contentMode: KitoSheetContentMode = .fitted) {
        self.detents = detents.isEmpty ? [.fit] : detents
        self.style = style
        self.showsGrabber = showsGrabber
        self.dismissesOnBackdropTap = dismissesOnBackdropTap
        self.dismissesOnDrag = dismissesOnDrag
        self.backdropOpacity = backdropOpacity
        self.blursBackdrop = blursBackdrop
        self.cornerRadius = cornerRadius
        self.background = background
        self.contentMode = contentMode
    }

    public static let `default` = KitoSheetConfiguration()

    /// Scrollable content with the given detents, e.g. `.scrollable(detents: [.fraction(0.5), .large])`.
    public static func scrollable(detents: [KitoSheetDetent] = [.fraction(0.55), .large]) -> KitoSheetConfiguration {
        KitoSheetConfiguration(detents: detents, contentMode: .scrollable)
    }
}

public extension View {
    /// A custom bottom sheet drawn above this view: detents you drag between, rubber-banding past
    /// the top, drag-down and tap-outside to dismiss, and attached, floating or glass styles.
    /// Attach it to a full-screen container.
    func kitoSheet<SheetContent: View>(isPresented: Binding<Bool>, configuration: KitoSheetConfiguration = .default,
                                       @ViewBuilder content: @escaping () -> SheetContent) -> some View {
        modifier(KitoSheetModifier(isPresented: isPresented, configuration: configuration, header: { EmptyView() }, sheet: content))
    }

    /// A custom bottom sheet with a fixed header (a title, a search field) above the content.
    /// The header never scrolls, and with `.scrollable` content it is, together with the
    /// grabber, the part of the sheet you drag.
    func kitoSheet<SheetHeader: View, SheetContent: View>(isPresented: Binding<Bool>, configuration: KitoSheetConfiguration = .default,
                                                          @ViewBuilder header: @escaping () -> SheetHeader,
                                                          @ViewBuilder content: @escaping () -> SheetContent) -> some View {
        modifier(KitoSheetModifier(isPresented: isPresented, configuration: configuration, header: header, sheet: content))
    }
}

struct KitoSheetModifier<SheetHeader: View, SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let configuration: KitoSheetConfiguration
    @ViewBuilder let header: () -> SheetHeader
    @ViewBuilder let sheet: () -> SheetContent

    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var detentIndex = 0
    @State private var drag: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var headerHeight: CGFloat = 0
    /// Scrollable mode: whether the content is scrolled to its top.
    @State private var scrollAtTop = true
    /// Scrollable mode: set when a drag on the content starts, true if it is pulling the sheet down.
    @State private var pullingSheet: Bool?

    private static var scrollSpace: String { "KitoSheetScroll" }
    private var scrollable: Bool { configuration.contentMode == .scrollable }

    private var animation: Animation { reduceMotion ? .easeInOut(duration: 0.25) : .spring(response: 0.42, dampingFraction: 0.84) }

    func body(content: Content) -> some View {
        content
            .blur(radius: isPresented && configuration.blursBackdrop ? 6 : 0)
            .overlay {
                GeometryReader { proxy in
                    let insets = proxy.safeAreaInsets
                    let screenHeight = proxy.size.height + insets.top + insets.bottom
                    let heights = configuration.detents.map { Self.resolve($0, content: contentHeight + headerHeight, screen: screenHeight, topInset: insets.top, grabber: configuration.showsGrabber) }
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
            VStack(spacing: 0) {
                if configuration.showsGrabber {
                    Capsule().fill(theme.colors.onSurface.opacity(0.25)).frame(width: 40, height: 5).padding(.top, 10).padding(.bottom, 6)
                        .accessibilityHidden(true)
                }
                header()
                    .fixedSize(horizontal: false, vertical: true)
                    .background(GeometryReader { g in Color.clear.preference(key: KitoSheetHeaderHeightKey.self, value: g.size.height) })
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .gesture(scrollable ? sheetDrag(heights: heights) : nil)

            if scrollable {
                ScrollView {
                    VStack(spacing: 0) {
                        GeometryReader { g in
                            Color.clear.preference(key: KitoSheetScrollTopKey.self, value: g.frame(in: .named(Self.scrollSpace)).minY)
                        }
                        .frame(height: 0)
                        sheet()
                            .background(GeometryReader { g in Color.clear.preference(key: KitoSheetContentHeightKey.self, value: g.size.height) })
                    }
                }
                .coordinateSpace(name: Self.scrollSpace)
                .onPreferenceChange(KitoSheetScrollTopKey.self) { scrollAtTop = $0 >= -1 }
                .simultaneousGesture(pullDownFromTop(heights: heights))
            } else {
                sheet()
                    .fixedSize(horizontal: false, vertical: true)
                    .background(GeometryReader { g in Color.clear.preference(key: KitoSheetContentHeightKey.self, value: g.size.height) })
                    .frame(maxHeight: .infinity, alignment: .top)
            }
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
        .onPreferenceChange(KitoSheetHeaderHeightKey.self) { headerHeight = $0 }
        .gesture(scrollable ? nil : sheetDrag(heights: heights))
        .accessibilityElement(children: .contain)
        .accessibilityAction(.escape) { dismiss() }
    }

    private func sheetDrag(heights: [CGFloat]) -> some Gesture {
        DragGesture()
            .onChanged { drag = $0.translation.height }
            .onEnded { value in settle(translation: value.translation.height, predicted: value.predictedEndTranslation.height, heights: heights) }
    }

    /// Scrollable mode: a drag on the content moves the sheet only if it starts downwards while
    /// the content is at its top; otherwise the scroll view has it.
    private func pullDownFromTop(heights: [CGFloat]) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if pullingSheet == nil { pullingSheet = scrollAtTop && value.translation.height > 0 }
                if pullingSheet == true { drag = max(value.translation.height, 0) }
            }
            .onEnded { value in
                defer { pullingSheet = nil }
                guard pullingSheet == true else { return }
                settle(translation: max(value.translation.height, 0), predicted: max(value.predictedEndTranslation.height, 0), heights: heights)
            }
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

struct KitoSheetHeaderHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

struct KitoSheetScrollTopKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

struct KitoSheetContentHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

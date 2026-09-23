//
//  KitoModalExtras.swift
//  KitoModals
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

// MARK: - Action menu

public struct KitoMenuAction: Identifiable {
    public let id = UUID()
    public var title: String
    public var systemImage: String?
    public var isDestructive: Bool
    public var action: @MainActor () -> Void

    public init(_ title: String, systemImage: String? = nil, isDestructive: Bool = false, action: @escaping @MainActor () -> Void = {}) {
        self.title = title
        self.systemImage = systemImage
        self.isDestructive = isDestructive
        self.action = action
    }
}

public extension View {
    /// A floating action sheet: a card of icon rows with an optional title and message, and a
    /// separate Cancel card below it.
    func kitoActionMenu(isPresented: Binding<Bool>, title: String? = nil, message: String? = nil,
                        actions: [KitoMenuAction], cancelTitle: String = "Cancel") -> some View {
        kitoSheet(isPresented: isPresented, configuration: KitoSheetConfiguration(style: .floating, showsGrabber: false, background: .clear)) {
            KitoActionMenuContent(isPresented: isPresented, title: title, message: message, actions: actions, cancelTitle: cancelTitle)
        }
    }
}

struct KitoActionMenuContent: View {
    @Binding var isPresented: Bool
    let title: String?
    let message: String?
    let actions: [KitoMenuAction]
    let cancelTitle: String
    @Environment(\.kitoTheme) private var theme

    var body: some View {
        VStack(spacing: 10) {
            VStack(spacing: 0) {
                if title != nil || message != nil {
                    VStack(spacing: 4) {
                        if let title { Text(title).font(.subheadline.weight(.semibold)) }
                        if let message { Text(message).font(.caption).foregroundStyle(theme.colors.onSurface.opacity(0.6)).multilineTextAlignment(.center) }
                    }
                    .padding(.vertical, 14).padding(.horizontal, 20)
                    Divider()
                }
                ForEach(Array(actions.enumerated()), id: \.element.id) { index, item in
                    Button {
                        isPresented = false
                        item.action()
                    } label: {
                        HStack(spacing: 14) {
                            if let symbol = item.systemImage {
                                Image(systemName: symbol).font(.body.weight(.semibold)).frame(width: 26)
                            }
                            Text(item.title).font(.body.weight(.medium))
                            Spacer()
                        }
                        .foregroundStyle(item.isDestructive ? theme.colors.danger : theme.colors.onSurface)
                        .padding(.horizontal, 20)
                        .frame(height: 56)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(KitoRowPressStyle())
                    if index < actions.count - 1 { Divider().padding(.leading, item.systemImage == nil ? 20 : 60) }
                }
            }
            .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(theme.colors.surface))

            Button { isPresented = false } label: {
                Text(cancelTitle).font(.body.weight(.semibold)).frame(maxWidth: .infinity).frame(height: 56)
                    .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(theme.colors.surface))
                    .foregroundStyle(theme.colors.onSurface)
            }
            .buttonStyle(KitoPressStyle())
        }
    }
}

struct KitoRowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.background(Color.primary.opacity(configuration.isPressed ? 0.08 : 0))
    }
}

// MARK: - Tooltip

public extension View {
    /// A bubble with an arrow pointing at this view, above or below it, for coach marks and hints.
    /// Tap it to dismiss.
    func kitoTooltip(isPresented: Binding<Bool>, _ text: String, systemImage: String? = nil, edge: VerticalEdge = .top) -> some View {
        modifier(KitoTooltipModifier(isPresented: isPresented, text: text, systemImage: systemImage, edge: edge))
    }
}

struct KitoTooltipModifier: ViewModifier {
    @Binding var isPresented: Bool
    let text: String
    let systemImage: String?
    let edge: VerticalEdge
    @Environment(\.kitoTheme) private var theme

    func body(content: Content) -> some View {
        content.overlay(alignment: edge == .top ? .top : .bottom) {
            if isPresented {
                VStack(spacing: 0) {
                    if edge == .bottom { arrow.rotationEffect(.degrees(180)) }
                    HStack(spacing: 8) {
                        if let systemImage { Image(systemName: systemImage) }
                        Text(text).font(.subheadline.weight(.semibold)).multilineTextAlignment(.leading)
                    }
                    .foregroundStyle(theme.colors.onPrimary)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.colors.primary))
                    if edge == .top { arrow }
                }
                .fixedSize()
                .alignmentGuide(edge == .top ? .top : .bottom) { dimensions in
                    edge == .top ? dimensions[.bottom] + 6 : dimensions[.top] - 6
                }
                .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
                .onTapGesture { withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { isPresented = false } }
                .transition(.scale(scale: 0.6, anchor: edge == .top ? .bottom : .top).combined(with: .opacity))
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Dismisses the tip")
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isPresented)
    }

    private var arrow: some View {
        KitoTooltipArrow().fill(theme.colors.primary).frame(width: 16, height: 8)
    }
}

struct KitoTooltipArrow: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

// MARK: - Hero card

/// Hosts `KitoHeroCard`s: a card tapped inside it expands to fill the container, App Store
/// Today style, and shrinks back when closed. Put the container around a scroll view of cards.
public struct KitoHeroContainer<Content: View>: View {
    @ViewBuilder let content: () -> Content
    @Namespace private var namespace
    @State private var presented: (id: String, collapsed: AnyView, expanded: AnyView)?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    private var animation: Animation { reduceMotion ? .easeInOut(duration: 0.25) : .spring(response: 0.5, dampingFraction: 0.84) }

    public var body: some View {
        ZStack {
            content()
                .environment(\.kitoHero, KitoHeroContext(namespace: namespace, expandedID: presented?.id, present: { id, collapsed, expanded in
                    withAnimation(animation) { presented = (id, collapsed, expanded) }
                }))
            if let presented {
                ZStack(alignment: .topTrailing) {
                    ScrollView {
                        VStack(spacing: 0) {
                            presented.collapsed
                                .matchedGeometryEffect(id: presented.id, in: namespace)
                                .frame(height: 440)
                                .clipped()
                            presented.expanded
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .background(Color(.systemBackground))
                    .ignoresSafeArea()
                    Button {
                        withAnimation(animation) { self.presented = nil }
                    } label: {
                        Image(systemName: "xmark").font(.system(size: 14, weight: .bold))
                            .frame(width: 34, height: 34)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 18)
                    .padding(.top, 8)
                    .accessibilityLabel("Close")
                }
                .zIndex(1)
                .transition(.identity)
            }
        }
    }
}

public struct KitoHeroContext {
    let namespace: Namespace.ID?
    let expandedID: String?
    let present: (String, AnyView, AnyView) -> Void
}

private struct KitoHeroKey: EnvironmentKey {
    static let defaultValue = KitoHeroContext(namespace: nil, expandedID: nil, present: { _, _, _ in })
}

extension EnvironmentValues {
    var kitoHero: KitoHeroContext {
        get { self[KitoHeroKey.self] }
        set { self[KitoHeroKey.self] = newValue }
    }
}

/// A card inside a `KitoHeroContainer`. `collapsed` is the card face (also the expanded
/// header); `expanded` is the story below it once opened.
public struct KitoHeroCard<Collapsed: View, Expanded: View>: View {
    let id: String
    let height: CGFloat
    @ViewBuilder let collapsed: () -> Collapsed
    @ViewBuilder let expanded: () -> Expanded
    @Environment(\.kitoHero) private var hero

    public init(id: String, height: CGFloat = 380, @ViewBuilder collapsed: @escaping () -> Collapsed, @ViewBuilder expanded: @escaping () -> Expanded) {
        self.id = id
        self.height = height
        self.collapsed = collapsed
        self.expanded = expanded
    }

    public var body: some View {
        Group {
            if hero.expandedID == id {
                Color.clear
            } else if let namespace = hero.namespace {
                collapsed()
                    .matchedGeometryEffect(id: id, in: namespace)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
            } else {
                collapsed().clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            }
        }
        .frame(height: height)
        .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .onTapGesture { hero.present(id, AnyView(collapsed()), AnyView(expanded())) }
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Opens the story")
    }
}

// MARK: - Slide to confirm

/// "Slide to pay": drag the knob to the end to confirm. It runs `onConfirm`, shows a spinner while
/// it does, and ends on a tick. Tap or VoiceOver's activate also works.
public struct KitoSlideToConfirm: View {
    let title: String
    let systemImage: String
    let tint: Color?
    let onConfirm: () async -> Void

    @Environment(\.kitoTheme) private var theme
    @State private var offset: CGFloat = 0
    @State private var phase: Phase = .idle
    @State private var shimmer = false

    enum Phase { case idle, working, done }

    public init(_ title: String = "Slide to confirm", systemImage: String = "chevron.right", tint: Color? = nil, onConfirm: @escaping () async -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.onConfirm = onConfirm
    }

    /// Past 85% of the track counts as a confirm.
    static func confirms(offset: CGFloat, track: CGFloat) -> Bool { track > 0 && offset >= track * 0.85 }

    public var body: some View {
        GeometryReader { geometry in
            let knob: CGFloat = 56
            let track = max(geometry.size.width - knob - 8, 1)
            let color = tint ?? theme.colors.primary
            ZStack(alignment: .leading) {
                Capsule().fill(color.opacity(0.15))
                Capsule().fill(color.opacity(0.35)).frame(width: offset + knob + 4)
                Text(phase == .done ? "Done" : title)
                    .font(.headline)
                    .foregroundStyle(theme.colors.onSurface.opacity(0.8))
                    .mask(
                        LinearGradient(colors: [.white.opacity(0.35), .white, .white.opacity(0.35)], startPoint: .leading, endPoint: .trailing)
                            .offset(x: shimmer ? 160 : -160)
                    )
                    .frame(maxWidth: .infinity)
                    .opacity(1 - Double(offset / track) * 0.9)
                Circle()
                    .fill(color)
                    .frame(width: knob, height: knob)
                    .overlay {
                        switch phase {
                        case .idle: Image(systemName: systemImage).font(.headline.bold()).foregroundStyle(theme.colors.onPrimary)
                        case .working: ProgressView().tint(theme.colors.onPrimary)
                        case .done: Image(systemName: "checkmark").font(.headline.bold()).foregroundStyle(theme.colors.onPrimary).transition(.scale)
                        }
                    }
                    .padding(4)
                    .offset(x: offset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                guard phase == .idle else { return }
                                offset = min(max(value.translation.width, 0), track)
                            }
                            .onEnded { _ in
                                guard phase == .idle else { return }
                                if Self.confirms(offset: offset, track: track) { confirm(track: track) }
                                else { withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { offset = 0 } }
                            }
                    )
            }
        }
        .frame(height: 64)
        .onAppear { withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) { shimmer = true } }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { if phase == .idle { confirm(track: nil) } }
    }

    private func confirm(track: CGFloat?) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            if let track { offset = track }
            phase = .working
        }
        Task {
            await onConfirm()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { phase = .done }
        }
    }
}

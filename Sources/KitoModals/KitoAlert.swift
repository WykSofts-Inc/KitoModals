//
//  KitoAlert.swift
//  KitoModals
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

public struct KitoAlertAction: Identifiable {
    public enum Role: Sendable { case primary, secondary, destructive, cancel }

    public let id = UUID()
    public var title: String
    public var role: Role
    public var action: @MainActor () -> Void

    public init(_ title: String, role: Role = .primary, action: @escaping @MainActor () -> Void = {}) {
        self.title = title
        self.role = role
        self.action = action
    }

    public static func cancel(_ title: String = "Cancel") -> KitoAlertAction { KitoAlertAction(title, role: .cancel) }
}

/// A custom alert: an icon that pops in on a tinted badge, a title, a message and actions that sit
/// side by side when two short ones fit, stacked otherwise. `celebrates` adds a confetti burst.
public struct KitoAlert: Identifiable {
    public let id = UUID()
    public var systemImage: String?
    /// The badge colour; nil uses the theme's primary, or danger when an action is destructive.
    public var tint: Color?
    public var title: String
    public var message: String?
    public var actions: [KitoAlertAction]
    public var celebrates: Bool

    public init(systemImage: String? = nil, tint: Color? = nil, title: String, message: String? = nil,
                actions: [KitoAlertAction] = [KitoAlertAction("OK")], celebrates: Bool = false) {
        self.systemImage = systemImage
        self.tint = tint
        self.title = title
        self.message = message
        self.actions = actions.isEmpty ? [KitoAlertAction("OK")] : actions
        self.celebrates = celebrates
    }

    /// Two actions whose titles are short enough sit side by side.
    static func laysOutHorizontally(_ actions: [KitoAlertAction]) -> Bool {
        actions.count == 2 && actions.allSatisfy { $0.title.count <= 12 }
    }

    var isDestructive: Bool { actions.contains { $0.role == .destructive } }
}

public extension View {
    /// Shows `alert` over this view while it's non-nil; any action, or a tap outside when there's a
    /// cancel action, clears it.
    func kitoAlert(_ alert: Binding<KitoAlert?>) -> some View {
        modifier(KitoAlertModifier(alert: alert))
    }
}

struct KitoAlertModifier: ViewModifier {
    @Binding var alert: KitoAlert?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay {
                ZStack {
                    if let alert {
                        Color.black.opacity(0.45)
                            .ignoresSafeArea()
                            .onTapGesture {
                                if let cancel = alert.actions.first(where: { $0.role == .cancel }) { finish(cancel) }
                            }
                            .transition(.opacity)
                        if alert.celebrates && !reduceMotion {
                            KitoConfetti().ignoresSafeArea().allowsHitTesting(false).transition(.opacity)
                        }
                        KitoAlertCard(alert: alert, onAction: finish)
                            .padding(.horizontal, 36)
                            .transition(reduceMotion ? .opacity : .scale(scale: 0.86).combined(with: .opacity))
                            .id(alert.id)
                    }
                }
                .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.38, dampingFraction: 0.78), value: alert?.id)
            }
    }

    private func finish(_ action: KitoAlertAction) {
        alert = nil
        action.action()
    }
}

struct KitoAlertCard: View {
    let alert: KitoAlert
    let onAction: (KitoAlertAction) -> Void

    @Environment(\.kitoTheme) private var theme
    @State private var badgeShown = false

    private var tint: Color { alert.tint ?? (alert.isDestructive ? theme.colors.danger : theme.colors.primary) }

    var body: some View {
        VStack(spacing: 14) {
            if let symbol = alert.systemImage {
                Image(systemName: symbol)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(tint)
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(tint.opacity(0.15)))
                    .overlay(Circle().stroke(tint.opacity(0.25), lineWidth: 6).scaleEffect(badgeShown ? 1.35 : 1).opacity(badgeShown ? 0 : 1))
                    .scaleEffect(badgeShown ? 1 : 0.4)
                    .symbolEffect(.bounce, value: badgeShown)
                    .accessibilityHidden(true)
            }
            VStack(spacing: 6) {
                Text(alert.title).font(.title3.bold()).multilineTextAlignment(.center)
                if let message = alert.message {
                    Text(message).font(.subheadline).foregroundStyle(theme.colors.onSurface.opacity(0.65)).multilineTextAlignment(.center)
                }
            }
            .foregroundStyle(theme.colors.onSurface)

            let buttons = ForEach(orderedActions) { action in button(for: action) }
            if KitoAlert.laysOutHorizontally(alert.actions) {
                HStack(spacing: 10) { buttons }.padding(.top, 4)
            } else {
                VStack(spacing: 10) { buttons }.padding(.top, 4)
            }
        }
        .padding(24)
        .frame(maxWidth: 360)
        .background(RoundedRectangle(cornerRadius: 30, style: .continuous).fill(theme.colors.surface))
        .shadow(color: .black.opacity(0.25), radius: 30, y: 14)
        .onAppear { withAnimation(.spring(response: 0.45, dampingFraction: 0.6).delay(0.08)) { badgeShown = true } }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    /// Cancel reads first when side by side, last when stacked — the platform's convention.
    private var orderedActions: [KitoAlertAction] {
        let cancels = alert.actions.filter { $0.role == .cancel }
        let others = alert.actions.filter { $0.role != .cancel }
        return KitoAlert.laysOutHorizontally(alert.actions) ? cancels + others : others + cancels
    }

    private func button(for action: KitoAlertAction) -> some View {
        let (fill, text): (Color, Color) = {
            switch action.role {
            case .primary: return (tint == theme.colors.danger ? theme.colors.primary : tint, theme.colors.onPrimary)
            case .destructive: return (theme.colors.danger, .white)
            case .secondary, .cancel: return (theme.colors.onSurface.opacity(0.08), theme.colors.onSurface)
            }
        }()
        return Button { onAction(action) } label: {
            Text(action.title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Capsule().fill(fill))
                .foregroundStyle(text)
        }
        .buttonStyle(KitoPressStyle())
    }
}

/// A short scale-down on press.
struct KitoPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// A two-and-a-half-second burst of confetti from the top.
public struct KitoConfetti: View {
    let colors: [Color]
    @State private var start = Date.now

    public init(colors: [Color] = [.pink, .orange, .yellow, .green, .blue, .purple]) {
        self.colors = colors
    }

    private struct Piece {
        let x: Double, speed: Double, drift: Double, spin: Double, size: Double, colorIndex: Int, delay: Double
    }

    private static let pieces: [Piece] = (0..<90).map { index in
        let seed = Double(index)
        func unit(_ n: Double) -> Double { (sin(seed * 12.9898 + n * 78.233) * 43758.5453).truncatingRemainder(dividingBy: 1).magnitude }
        return Piece(x: unit(1), speed: 0.55 + unit(2) * 0.6, drift: unit(3) - 0.5, spin: unit(4) * 8, size: 6 + unit(5) * 6, colorIndex: index, delay: unit(6) * 0.35)
    }

    public var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSince(start)
            Canvas { context, size in
                guard t < 3 else { return }
                for piece in Self.pieces {
                    let local = max(t - piece.delay, 0)
                    let y = -20 + local * piece.speed * size.height * 0.9 + 60 * local * local
                    let x = piece.x * size.width + sin(local * 3 + piece.spin) * 30 * piece.drift * 2
                    guard y < size.height + 20 else { continue }
                    var shard = context
                    shard.opacity = min(1, max(0, 2.6 - local))
                    shard.translateBy(x: x, y: y)
                    shard.rotate(by: .radians(local * piece.spin))
                    let rect = CGRect(x: -piece.size / 2, y: -piece.size / 4, width: piece.size, height: piece.size / 2)
                    shard.fill(Path(roundedRect: rect, cornerRadius: 1.5), with: .color(colors[piece.colorIndex % colors.count]))
                }
            }
        }
        .onAppear { start = .now }
        .accessibilityHidden(true)
    }
}

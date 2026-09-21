//
//  KitoStatusDialog.swift
//  KitoModals
//
//  Created by Wycliff on 4/19/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// Blocking, animated status feedback for an operation with a real
/// out-of-band effect — a payment charge, a submitted form — where a toast
/// (non-blocking, dismissable) would be the wrong weight. `.pending` shows a
/// spinner and should be replaced with `.success`/`.failure` once the async
/// work resolves; those two auto-dismiss after `autoDismissAfter` seconds.
public enum KitoStatusDialogState: Equatable {
    case pending(message: String? = nil)
    case success(message: String? = nil)
    case failure(message: String? = nil)

    var message: String? {
        switch self {
        case .pending(let m), .success(let m), .failure(let m): return m
        }
    }
}

public struct KitoStatusDialogView: View {
    @Environment(\.kitoTheme) private var theme
    let state: KitoStatusDialogState

    @State private var iconTrim: CGFloat = 0
    @State private var circleScale: CGFloat = 0.6
    @State private var isSpinning = false

    public init(state: KitoStatusDialogState) {
        self.state = state
    }

    public var body: some View {
        VStack(spacing: theme.spacing.md) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 72, height: 72)

                switch state {
                case .pending:
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(theme.colors.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 36, height: 36)
                        .rotationEffect(.degrees(isSpinning ? 360 : 0))
                        .animation(.linear(duration: 0.9).repeatForever(autoreverses: false), value: isSpinning)
                case .success:
                    KitoCheckmarkShape()
                        .trim(from: 0, to: iconTrim)
                        .stroke(theme.colors.success, style: StrokeStyle(lineWidth: 4.5, lineCap: .round, lineJoin: .round))
                        .frame(width: 36, height: 36)
                case .failure:
                    KitoXmarkShape()
                        .trim(from: 0, to: iconTrim)
                        .stroke(theme.colors.danger, style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
                        .frame(width: 36, height: 36)
                }
            }
            .scaleEffect(circleScale)

            if let message = state.message {
                Text(message)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.onSurface)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(theme.spacing.xl)
        .frame(minWidth: 180)
        .background(theme.colors.surface, in: RoundedRectangle(cornerRadius: theme.radii.xl))
        .shadow(color: .black.opacity(0.25), radius: 24, y: 10)
        .onAppear { animateIn() }
        .onChange(of: state) { _, _ in animateIn() }
    }

    private var accentColor: Color {
        switch state {
        case .pending: return theme.colors.primary
        case .success: return theme.colors.success
        case .failure: return theme.colors.danger
        }
    }

    private func animateIn() {
        iconTrim = 0
        circleScale = 0.6
        isSpinning = false
        withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) { circleScale = 1 }
        switch state {
        case .pending:
            isSpinning = true
        case .success, .failure:
            withAnimation(.easeOut(duration: 0.45).delay(0.1)) { iconTrim = 1 }
        }
    }
}

private struct KitoStatusDialogModifier: ViewModifier {
    @Binding var state: KitoStatusDialogState?
    let autoDismissAfter: Double?
    let dimsBackground: Bool

    func body(content: Content) -> some View {
        content.overlay {
            if let state {
                ZStack {
                    if dimsBackground {
                        Color.black.opacity(0.35)
                            .ignoresSafeArea()
                            .transition(.opacity)
                    }
                    KitoStatusDialogView(state: state)
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                }
                .task(id: taskKey(for: state)) {
                    guard case .pending = state, let autoDismissAfter else { return }
                    try? await Task.sleep(nanoseconds: UInt64(autoDismissAfter * 1_000_000_000))
                    guard !Task.isCancelled else { return }
                    self.state = nil
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: state != nil)
    }

    /// `.task(id:)` needs a `Hashable` key that changes only when the *kind*
    /// of state changes, not on every message-string tweak while pending.
    private func taskKey(for state: KitoStatusDialogState) -> String {
        switch state {
        case .pending: return "pending"
        case .success: return "success"
        case .failure: return "failure"
        }
    }
}

public extension View {
    /// Drive a blocking success/failure/pending dialog from one optional
    /// binding. Set it to `.pending(...)` when work starts, then to
    /// `.success`/`.failure` when it resolves — the dialog animates between
    /// states in place and auto-dismisses non-pending states after
    /// `autoDismissAfter` seconds (`nil` to require manual dismissal).
    func kitoStatusDialog(
        _ state: Binding<KitoStatusDialogState?>,
        autoDismissAfter: Double? = 1.6,
        dimsBackground: Bool = true
    ) -> some View {
        modifier(KitoStatusDialogModifier(state: state, autoDismissAfter: autoDismissAfter, dimsBackground: dimsBackground))
    }
}

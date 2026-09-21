//
//  KitoConfirmationDialog.swift
//  KitoModals
//
//  Created by Wycliff on 4/16/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

public struct KitoConfirmation: Identifiable {
    public let id = UUID()
    public var title: String
    public var message: String?
    public var confirmTitle: String
    public var isDestructive: Bool
    public var onConfirm: @MainActor () -> Void

    public init(
        title: String,
        message: String? = nil,
        confirmTitle: String = "Confirm",
        isDestructive: Bool = false,
        onConfirm: @escaping @MainActor () -> Void
    ) {
        self.title = title
        self.message = message
        self.confirmTitle = confirmTitle
        self.isDestructive = isDestructive
        self.onConfirm = onConfirm
    }
}

private struct KitoConfirmationModifier: ViewModifier {
    @Binding var confirmation: KitoConfirmation?

    func body(content: Content) -> some View {
        content.confirmationDialog(
            confirmation?.title ?? "",
            isPresented: Binding(get: { confirmation != nil }, set: { if !$0 { confirmation = nil } }),
            presenting: confirmation
        ) { item in
            Button(item.confirmTitle, role: item.isDestructive ? .destructive : nil) {
                item.onConfirm()
                confirmation = nil
            }
            Button("Cancel", role: .cancel) { confirmation = nil }
        } message: { item in
            if let message = item.message { Text(message) }
        }
    }
}

public extension View {
    /// One binding drives an entire confirm/cancel flow — no separate
    /// `isPresented` bool to keep in sync with the message being shown.
    ///
    /// ```swift
    /// @State private var confirmation: KitoConfirmation?
    ///
    /// content.kitoConfirmation($confirmation)
    /// // later, to trigger it:
    /// confirmation = KitoConfirmation(
    ///     title: "Delete card?",
    ///     message: "This can't be undone.",
    ///     confirmTitle: "Delete",
    ///     isDestructive: true
    /// ) { viewModel.deleteCard() }
    /// ```
    func kitoConfirmation(_ confirmation: Binding<KitoConfirmation?>) -> some View {
        modifier(KitoConfirmationModifier(confirmation: confirmation))
    }
}

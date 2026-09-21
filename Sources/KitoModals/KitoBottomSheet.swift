//
//  KitoBottomSheet.swift
//  KitoModals
//
//  Created by Wycliff on 4/15/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// Presents `content` for whichever `route` is set, themed with a drag
/// indicator and rounded top corners pulled from `kitoTheme`.
public struct KitoBottomSheetModifier<Route: KitoSheetRoute, SheetContent: View>: ViewModifier {
    @Bindable var presenter: KitoSheetPresenter<Route>
    let detents: Set<PresentationDetent>
    @ViewBuilder let content: (Route) -> SheetContent

    public func body(content base: Content) -> some View {
        base.sheet(item: $presenter.route) { route in
            content(route)
                .presentationDetents(detents)
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
        }
    }
}

public extension View {
    /// Route-based bottom sheet. Only one sheet can be active at a time,
    /// enforced by `KitoSheetPresenter.route` being a single optional.
    ///
    /// ```swift
    /// enum Sheet: String, KitoSheetRoute { case filters, share; var id: Self { self } }
    /// @State var presenter = KitoSheetPresenter<Sheet>()
    ///
    /// content.kitoBottomSheet(presenter: presenter, detents: [.medium, .large]) { route in
    ///     switch route {
    ///     case .filters: FiltersView()
    ///     case .share: ShareView()
    ///     }
    /// }
    /// ```
    func kitoBottomSheet<Route: KitoSheetRoute, SheetContent: View>(
        presenter: KitoSheetPresenter<Route>,
        detents: Set<PresentationDetent> = [.medium],
        @ViewBuilder content: @escaping (Route) -> SheetContent
    ) -> some View {
        modifier(KitoBottomSheetModifier(presenter: presenter, detents: detents, content: content))
    }
}

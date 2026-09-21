//
//  KitoSheetPresenter.swift
//  KitoModals
//
//  Created by Wycliff on 4/17/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Observation
import KitoCore

/// Owns "which sheet is showing" for a screen. A screen exposes one of these
/// instead of a grab-bag of `@State private var isShowingX: Bool` flags that
/// can't express "only one sheet at a time" — this type makes that invariant
/// structural: `route` is a single optional, not N booleans that can disagree.
@Observable
public final class KitoSheetPresenter<Route: KitoSheetRoute>: KitoViewModel {
    public var route: Route?

    public init(route: Route? = nil) {
        self.route = route
    }

    public func present(_ route: Route) {
        self.route = route
    }

    public func dismiss() {
        route = nil
    }
}

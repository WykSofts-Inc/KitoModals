//
//  KitoModalsTests.swift
//  KitoModals
//
//  Created by Wycliff on 4/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import XCTest
@testable import KitoModals

private enum TestRoute: String, KitoSheetRoute {
    case a, b
    var id: Self { self }
}

@MainActor
final class KitoModalsTests: XCTestCase {
    func testPresentSetsRoute() {
        let presenter = KitoSheetPresenter<TestRoute>()
        presenter.present(.a)
        XCTAssertEqual(presenter.route, .a)
    }

    func testDismissClearsRoute() {
        let presenter = KitoSheetPresenter<TestRoute>(route: .b)
        presenter.dismiss()
        XCTAssertNil(presenter.route)
    }

    func testOnlyOneRouteActiveAtATime() {
        let presenter = KitoSheetPresenter<TestRoute>()
        presenter.present(.a)
        presenter.present(.b)
        XCTAssertEqual(presenter.route, .b, "presenting a new route replaces the old one, never stacks")
    }

    func testStatusDialogMessageExtraction() {
        XCTAssertEqual(KitoStatusDialogState.success(message: "Paid").message, "Paid")
        XCTAssertNil(KitoStatusDialogState.pending().message)
    }

    func testStatusDialogStatesAreDistinctByCase() {
        XCTAssertNotEqual(KitoStatusDialogState.success(message: "x"), .failure(message: "x"))
    }
}

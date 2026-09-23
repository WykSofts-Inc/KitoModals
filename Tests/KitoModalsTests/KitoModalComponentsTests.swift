//
//  KitoModalComponentsTests.swift
//  KitoModals
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import XCTest
import SwiftUI
@testable import KitoModals

final class KitoModalComponentsTests: XCTestCase {
    private typealias Sheet = KitoSheetModifier<EmptyView>

    func testDetentsResolveAndClampToTheScreen() {
        XCTAssertEqual(Sheet.resolve(.fit, content: 300, screen: 874, topInset: 62, grabber: true), 329)
        XCTAssertEqual(Sheet.resolve(.fit, content: 300, screen: 874, topInset: 62, grabber: false), 308)
        XCTAssertEqual(Sheet.resolve(.fraction(0.5), content: 0, screen: 800, topInset: 0, grabber: true), 400)
        XCTAssertEqual(Sheet.resolve(.height(240), content: 0, screen: 800, topInset: 0, grabber: true), 240)
        XCTAssertEqual(Sheet.resolve(.large, content: 0, screen: 874, topInset: 62, grabber: true), 802)
        XCTAssertEqual(Sheet.resolve(.height(5_000), content: 0, screen: 874, topInset: 62, grabber: true), 802, "never taller than large")
        XCTAssertEqual(Sheet.resolve(.height(10), content: 0, screen: 874, topInset: 62, grabber: true), 60, "never a sliver")
    }

    func testDraggingDownShrinksOneForOne() {
        XCTAssertEqual(Sheet.visibleHeight(current: 400, tallest: 800, drag: 120), 280)
        XCTAssertEqual(Sheet.visibleHeight(current: 400, tallest: 800, drag: 900), 0)
    }

    func testDraggingUpGrowsThenRubberBands() {
        XCTAssertEqual(Sheet.visibleHeight(current: 400, tallest: 800, drag: -200), 600, "free travel to the tallest detent")
        let past = Sheet.visibleHeight(current: 800, tallest: 800, drag: -300)
        XCTAssertGreaterThan(past, 800)
        XCTAssertLessThan(past, 800 + 800 * 0.12, "resists past the top")
    }

    func testTheNearestDetentWins() {
        XCTAssertEqual(Sheet.nearestDetent(to: 520, in: [300, 500, 800]), 1)
        XCTAssertEqual(Sheet.nearestDetent(to: 10, in: [300, 500, 800]), 0)
        XCTAssertEqual(Sheet.nearestDetent(to: 2_000, in: [300, 500, 800]), 2)
    }

    func testEmptyDetentsFallBackToFit() {
        XCTAssertEqual(KitoSheetConfiguration(detents: []).detents, [.fit])
    }

    func testTwoShortActionsSitSideBySide() {
        XCTAssertTrue(KitoAlert.laysOutHorizontally([.cancel(), KitoAlertAction("Delete", role: .destructive)]))
        XCTAssertFalse(KitoAlert.laysOutHorizontally([.cancel(), KitoAlertAction("Delete my account forever", role: .destructive)]))
        XCTAssertFalse(KitoAlert.laysOutHorizontally([KitoAlertAction("A"), KitoAlertAction("B"), .cancel()]))
    }

    func testAnAlertAlwaysHasAnAction() {
        XCTAssertEqual(KitoAlert(title: "Hi", actions: []).actions.map(\.title), ["OK"])
        XCTAssertTrue(KitoAlert(title: "Delete?", actions: [KitoAlertAction("Delete", role: .destructive)]).isDestructive)
    }

    func testSlidingPast85PercentConfirms() {
        XCTAssertTrue(KitoSlideToConfirm.confirms(offset: 86, track: 100))
        XCTAssertFalse(KitoSlideToConfirm.confirms(offset: 80, track: 100))
        XCTAssertFalse(KitoSlideToConfirm.confirms(offset: 0, track: 0))
    }
}

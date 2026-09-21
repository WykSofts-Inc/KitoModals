//
//  KitoSheetRoute.swift
//  KitoModals
//
//  Created by Wycliff on 4/18/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

/// Conform an enum of your app's sheet destinations to this so one
/// `KitoSheetPresenter` can drive all of them — `case editProfile`,
/// `case cardDetails(Card)`, etc.
public protocol KitoSheetRoute: Identifiable, Equatable {}

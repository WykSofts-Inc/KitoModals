// swift-tools-version: 5.9
//
//  Package.swift
//  KitoModals
//
//  Created by Wycliff on 4/14/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//


import PackageDescription

let package = Package(
    name: "KitoModals",
    platforms: [.iOS(.v17)],
    products: [.library(name: "KitoModals", targets: ["KitoModals"])],
    dependencies: [
        .package(url: "https://github.com/WykSofts-Inc/KitoCore.git", from: "1.0.0"),
    ],
    targets: [
        .target(name: "KitoModals", dependencies: [.product(name: "KitoCore", package: "KitoCore")]),
        .testTarget(name: "KitoModalsTests", dependencies: ["KitoModals"]),
    ]
)

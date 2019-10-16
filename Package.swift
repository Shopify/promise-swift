// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Promise-swift",
  products: [
    .library(
      name: "Promise-swift",
      targets: [
        "Promise"
      ]
    ),
  ],
  targets: [
    .target(
      name: "Promise"
    ),
    .testTarget(
      name: "PromiseTests",
      dependencies: [
        "Promise",
      ]
    ),
  ]
)

// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DayPlanner",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "DayPlannerCore", targets: ["DayPlannerCore"]),
        .executable(name: "DayPlanner", targets: ["DayPlannerApp"]),
    ],
    targets: [
        .target(name: "DayPlannerCore"),
        .executableTarget(
            name: "DayPlannerApp",
            dependencies: ["DayPlannerCore"]
        ),
        .testTarget(
            name: "DayPlannerCoreTests",
            dependencies: ["DayPlannerCore"]
        ),
    ]
)

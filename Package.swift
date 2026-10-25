// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DayPlanner",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "DayPlannerCore", targets: ["DayPlannerCore"]),
        .executable(name: "DayPlanner", targets: ["DayPlannerApp"]),
        .executable(name: "DayPlannerTests", targets: ["DayPlannerTestRunner"]),
    ],
    targets: [
        .target(name: "DayPlannerCore"),
        .target(
            name: "DayPlannerSuite",
            dependencies: ["DayPlannerCore"]
        ),
        .executableTarget(
            name: "DayPlannerApp",
            dependencies: ["DayPlannerCore"]
        ),
        .executableTarget(
            name: "DayPlannerTestRunner",
            dependencies: ["DayPlannerSuite"]
        ),
        .testTarget(
            name: "DayPlannerCoreTests",
            dependencies: ["DayPlannerSuite"]
        ),
    ]
)

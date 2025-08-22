import XCTest
import SnapshotTesting
@testable import Tracker

final class TrackersVCSnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
        isRecording = false
    }

    private func makeSUT() -> UIViewController {
        let vc = TrackersViewController()
        vc.loadViewIfNeeded()
        return vc
    }

    // Светлая тема
    func test_MainScreen_Light_AutoSize() {
        let vc = makeSUT()
        let size = UIScreen.main.bounds.size
        let traits = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceStyle: .light),
            UITraitCollection(displayScale: UIScreen.main.scale)
        ])
        assertSnapshot(of: vc, as: .image(on: .init(size: size, traits: traits)))
    }

    // Тёмная тема
    func test_MainScreen_Dark_AutoSize() {
        let vc = makeSUT()
        let size = UIScreen.main.bounds.size
        let traits = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceStyle: .dark),
            UITraitCollection(displayScale: UIScreen.main.scale)
        ])
        assertSnapshot(of: vc, as: .image(on: .init(size: size, traits: traits)))
    }
}

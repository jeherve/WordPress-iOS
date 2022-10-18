import Nimble
import XCTest
@testable import WordPress

class StatsSegmentedControlDataTests: XCTestCase {

    func testDifferenceLabel() {
        expect(StatsSegmentedControlData.fixture(difference: -1, differencePercent: -1).differenceLabel)
            == ""
        expect(StatsSegmentedControlData.fixture(difference: -1, differencePercent: 0).differenceLabel)
            == ""
        expect(StatsSegmentedControlData.fixture(difference: -1, differencePercent: 1).differenceLabel)
            == ""
        expect(StatsSegmentedControlData.fixture(difference: 0, differencePercent: -1).differenceLabel)
            == ""
        expect(StatsSegmentedControlData.fixture(difference: 0, differencePercent: 0).differenceLabel)
            == ""
        expect(StatsSegmentedControlData.fixture(difference: 0, differencePercent: 1).differenceLabel)
            == ""
        expect(StatsSegmentedControlData.fixture(difference: 1, differencePercent: -1).differenceLabel)
            == ""
        expect(StatsSegmentedControlData.fixture(difference: 1, differencePercent: 0).differenceLabel)
            == ""
        expect(StatsSegmentedControlData.fixture(difference: 1, differencePercent: 1).differenceLabel)
            == ""
    }
}

extension StatsSegmentedControlData {

    static func fixture(
        segmentTitle: String = "title",
        segmentData: Int = 0,
        segmentPrevData: Int = 1,
        difference: Int = 2,
        differenceText: String = "text",
        differencePercent: Int = 3
    ) -> StatsSegmentedControlData {
        StatsSegmentedControlData(
            segmentTitle: segmentTitle,
            segmentData: segmentData,
            segmentPrevData: segmentPrevData,
            difference: difference,
            differenceText: differenceText,
            differencePercent: differencePercent
        )
    }
}

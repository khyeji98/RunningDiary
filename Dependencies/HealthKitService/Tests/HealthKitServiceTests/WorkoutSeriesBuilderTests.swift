import Foundation
import Models
import Testing

@testable import HealthKitService

@Suite("WorkoutSeriesBuilder.downsample")
struct WorkoutSeriesBuilderTests {

    // MARK: - 빈 입력 / 단일 샘플

    @Test("빈 입력이면 빈 배열을 반환한다")
    func downsample_returnsEmpty_whenSamplesEmpty() {
        // Given
        let samples: [(offset: TimeInterval, value: Double)] = []
        let expectedPoints: [SeriesPoint] = []

        // When
        let result = WorkoutSeriesBuilder.downsample(samples, intervalSec: 5)

        // Then
        #expect(result == expectedPoints)
    }

    @Test("단일 샘플은 버킷 규칙대로 t가 계산된 포인트 1개를 반환한다")
    func downsample_returnsSinglePoint_whenSingleSample() {
        // Given
        let samples: [(offset: TimeInterval, value: Double)] = [(offset: 12, value: 100)]
        let expectedPoints = [SeriesPoint(t: 10, v: 100)]

        // When
        let result = WorkoutSeriesBuilder.downsample(samples, intervalSec: 5)

        // Then
        #expect(result == expectedPoints)
    }

    // MARK: - 버킷 평균

    @Test("같은 버킷에 속한 샘플은 값이 평균되어 하나의 포인트가 된다")
    func downsample_averagesValues_whenSamplesShareBucket() {
        // Given
        let samples: [(offset: TimeInterval, value: Double)] = [
            (offset: 10, value: 100),
            (offset: 12, value: 110),
            (offset: 14, value: 120),
        ]
        let expectedPoints = [SeriesPoint(t: 10, v: 110)]

        // When
        let result = WorkoutSeriesBuilder.downsample(samples, intervalSec: 5)

        // Then
        #expect(result == expectedPoints)
    }

    @Test("서로 다른 버킷의 샘플은 각각 독립된 포인트로 분리된다")
    func downsample_separatesPoints_whenSamplesInDifferentBuckets() {
        // Given
        let samples: [(offset: TimeInterval, value: Double)] = [
            (offset: 10, value: 100),
            (offset: 12, value: 110),
            (offset: 14, value: 120),
            (offset: 20, value: 200),
        ]
        let expectedPoints = [
            SeriesPoint(t: 10, v: 110),
            SeriesPoint(t: 20, v: 200),
        ]

        // When
        let result = WorkoutSeriesBuilder.downsample(samples, intervalSec: 5)

        // Then
        #expect(result == expectedPoints)
    }

    // MARK: - maxPoints 상한 / 결정성

    @Test("포인트 개수가 maxPoints를 초과하면 균등 축소되어 정확히 maxPoints개가 된다")
    func downsample_reducesToMaxPoints_whenPointsExceedMaxPoints() {
        // Given
        let samples: [(offset: TimeInterval, value: Double)] = (0..<1_000).map {
            (offset: TimeInterval($0), value: Double($0))
        }
        let maxPoints = 10
        let expectedCount = maxPoints
        let expectedFirstPoint = SeriesPoint(t: 0, v: 0)
        let expectedLastPoint = SeriesPoint(t: 900, v: 900)

        // When
        let result = WorkoutSeriesBuilder.downsample(samples, intervalSec: 1, maxPoints: maxPoints)

        // Then
        #expect(result.count == expectedCount)
        #expect(result.first == expectedFirstPoint)
        #expect(result.last == expectedLastPoint)
    }

    @Test("동일한 입력으로 반복 호출해도 항상 같은 결과를 반환한다")
    func downsample_isDeterministic_whenCalledRepeatedly() {
        // Given
        let samples: [(offset: TimeInterval, value: Double)] = (0..<1_000).map {
            (offset: TimeInterval($0), value: Double($0))
        }
        let maxPoints = 10

        // When
        let firstResult = WorkoutSeriesBuilder.downsample(samples, intervalSec: 1, maxPoints: maxPoints)
        let secondResult = WorkoutSeriesBuilder.downsample(samples, intervalSec: 1, maxPoints: maxPoints)

        // Then
        #expect(firstResult == secondResult)
    }
}

import Foundation
import Testing

@testable import Models

@Suite("DetailedWorkout.toHealthKitWorkout")
struct DetailedWorkoutMapperTests {

    // MARK: - 파생 평균 매핑

    @Test("7개 시계열의 파생 평균이 대응 평균 필드로 매핑된다")
    func toHealthKitWorkout_mapsDerivedAverages_toScalarFields() {
        // Given
        let expectedHeartRate = 150
        let expectedCadence = 170
        let expectedVerticalOscillation = 8.4
        let expectedGroundContactTime = 245.0
        let expectedStepLength = 1.12
        let expectedPower = 300.0
        let expectedStrideLength = 1.35
        let workout = makeDetailedWorkout(
            heartRateSamples: makeSamples([148, 152]),
            cadenceSamples: makeSamples([168, 172]),
            runningVerticalOscillationSamples: makeSamples([8.0, 8.8]),
            runningGroundContactTimeSamples: makeSamples([240.0, 250.0]),
            walkingStepLengthSamples: makeSamples([1.10, 1.14]),
            runningPowerSamples: makeSamples([280.0, 320.0]),
            runningStrideLengthSamples: makeSamples([1.30, 1.40])
        )

        // When
        let result = workout.toHealthKitWorkout()

        // Then
        #expect(result.averageHeartRate == expectedHeartRate)
        #expect(result.averageCadence == expectedCadence)
        #expect(abs(result.runningVerticalOscillation - expectedVerticalOscillation) < 0.000_001)
        #expect(result.runningGroundContactTime == expectedGroundContactTime)
        #expect(abs(result.walkingStepLength - expectedStepLength) < 0.000_001)
        #expect(result.runningPower == expectedPower)
        #expect(result.runningStrideLength == expectedStrideLength)
    }

    @Test("모든 시계열이 비면 평균 필드가 전부 0이다")
    func toHealthKitWorkout_mapsAllAveragesToZero_whenAllSeriesEmpty() {
        // Given
        let workout = makeDetailedWorkout()

        // When
        let result = workout.toHealthKitWorkout()

        // Then
        #expect(result.averageHeartRate == 0)
        #expect(result.averageCadence == 0)
        #expect(result.runningVerticalOscillation == 0)
        #expect(result.runningGroundContactTime == 0)
        #expect(result.walkingStepLength == 0)
        #expect(result.runningPower == 0)
        #expect(result.runningStrideLength == 0)
    }

    // MARK: - 정체성 / 스칼라 보존 (컴파일러가 못 잡는 위험)

    @Test("id/distance/duration/averagePace/startTime/endTime을 그대로 전달한다")
    func toHealthKitWorkout_preservesIdentityAndTimes() {
        // Given: HealthKitWorkout.init의 id 기본값이 UUID()라 인자 누락 시 조용히 새 UUID가 발급된다
        let expectedID = UUID()
        let expectedDistance = 7.42
        let expectedDuration: TimeInterval = 2550
        let expectedPace = "5'44\""
        let expectedStart = Date(timeIntervalSince1970: 1_000_000)
        let expectedEnd = Date(timeIntervalSince1970: 1_002_550)
        let workout = DetailedWorkout(
            id: expectedID,
            distance: expectedDistance,
            duration: expectedDuration,
            averagePace: expectedPace,
            startDate: expectedStart,
            endDate: expectedEnd
        )

        // When
        let result = workout.toHealthKitWorkout()

        // Then
        #expect(result.id == expectedID)
        #expect(result.distance == expectedDistance)
        #expect(result.duration == expectedDuration)
        #expect(result.averagePace == expectedPace)
        #expect(result.startTime == expectedStart)
        #expect(result.endTime == expectedEnd)
    }

    @Test("activeEnergyBurned/restingHeartRate/heartRateRecoveryOneMinute를 그대로 전달한다")
    func toHealthKitWorkout_preservesScalarMetrics() {
        // Given
        let expectedEnergy = 512.3
        let expectedResting = 58.0
        let expectedRecovery = 32.0
        let workout = makeDetailedWorkout(
            activeEnergyBurned: expectedEnergy,
            restingHeartRate: expectedResting,
            heartRateRecoveryOneMinute: expectedRecovery
        )

        // When
        let result = workout.toHealthKitWorkout()

        // Then
        #expect(result.activeEnergyBurned == expectedEnergy)
        #expect(result.restingHeartRate == expectedResting)
        #expect(result.heartRateRecoveryOneMinute == expectedRecovery)
    }

    @Test("routeData/splits/series를 그대로 전달한다")
    func toHealthKitWorkout_preservesRouteAndSplitsAndSeries() {
        // Given: splits([])와 series(nil) 기본값이라 누락 시 조용히 소실된다
        let expectedRouteData = Data([0x01, 0x02, 0x03])
        let expectedSplits = [
            WorkoutSplit(
                index: 1,
                distanceKm: 1.0,
                durationSec: 330,
                paceSecondsPerKm: 330,
                averageHeartRate: 148,
                averageCadence: 172,
                elevationGainM: 4.2
            ),
        ]
        let expectedSeries = WorkoutSeries(
            sampleIntervalSec: 5,
            heartRate: [SeriesPoint(t: 0, v: 132)],
            paceSecondsPerKm: [SeriesPoint(t: 0, v: 360)],
            cadence: [SeriesPoint(t: 0, v: 168)],
            elevation: [ElevationPoint(distanceM: 0, altitude: 12.4)]
        )
        let workout = DetailedWorkout(
            distance: 5.0,
            duration: 1800,
            averagePace: "6'00\"",
            routeData: expectedRouteData,
            startDate: .now,
            endDate: .now,
            splits: expectedSplits,
            series: expectedSeries
        )

        // When
        let result = workout.toHealthKitWorkout()

        // Then
        #expect(result.routeData == expectedRouteData)
        #expect(result.splits == expectedSplits)
        #expect(result.series == expectedSeries)
    }

    @Test("yearMonthDay는 startTime에서 파생된다")
    func toHealthKitWorkout_derivesYearMonthDay_fromStartTime() {
        // Given
        let startDate = Date(timeIntervalSince1970: 1_000_000)
        let expectedYearMonthDay = YearMonthDay(date: startDate)
        let workout = DetailedWorkout(
            distance: 5.0,
            duration: 1800,
            averagePace: "6'00\"",
            startDate: startDate,
            endDate: startDate.addingTimeInterval(1800)
        )

        // When
        let result = workout.toHealthKitWorkout()

        // Then
        #expect(result.yearMonthDay == expectedYearMonthDay)
    }

    @Test("시계열이 비면 formatted 표시가 빈 문자열이 된다")
    func toHealthKitWorkout_producesEmptyFormattedString_whenMetricIsZero() {
        // Given
        let expectedEmpty = ""
        let workout = makeDetailedWorkout()

        // When
        let result = workout.toHealthKitWorkout()

        // Then
        #expect(result.formattedAverageHeartRate == expectedEmpty)
        #expect(result.formattedAverageCadence == expectedEmpty)
        #expect(result.formattedRunningPower == expectedEmpty)
        #expect(result.formattedVerticalOscillation == expectedEmpty)
        #expect(result.formattedGroundContactTime == expectedEmpty)
    }
}

// MARK: - Helpers

private extension DetailedWorkoutMapperTests {
    func makeSamples(_ values: [Double]) -> [MetricSample] {
        values.enumerated().map {
            MetricSample(offsetSec: TimeInterval($0.offset), value: $0.element)
        }
    }

    func makeDetailedWorkout(
        heartRateSamples: [MetricSample] = [],
        cadenceSamples: [MetricSample] = [],
        runningVerticalOscillationSamples: [MetricSample] = [],
        runningGroundContactTimeSamples: [MetricSample] = [],
        walkingStepLengthSamples: [MetricSample] = [],
        runningPowerSamples: [MetricSample] = [],
        runningStrideLengthSamples: [MetricSample] = [],
        activeEnergyBurned: Double = 0,
        restingHeartRate: Double = 0,
        heartRateRecoveryOneMinute: Double = 0
    ) -> DetailedWorkout {
        DetailedWorkout(
            distance: 5.0,
            duration: 1800,
            averagePace: "6'00\"",
            heartRateSamples: heartRateSamples,
            cadenceSamples: cadenceSamples,
            runningVerticalOscillationSamples: runningVerticalOscillationSamples,
            runningGroundContactTimeSamples: runningGroundContactTimeSamples,
            walkingStepLengthSamples: walkingStepLengthSamples,
            runningPowerSamples: runningPowerSamples,
            runningStrideLengthSamples: runningStrideLengthSamples,
            activeEnergyBurned: activeEnergyBurned,
            restingHeartRate: restingHeartRate,
            heartRateRecoveryOneMinute: heartRateRecoveryOneMinute,
            startDate: .now,
            endDate: .now
        )
    }
}

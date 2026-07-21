import Foundation
import Testing

@testable import Models

@Suite("DetailedWorkout 평균 지표")
struct DetailedWorkoutTests {

    // MARK: - 빈 시계열 → 0

    @Test("심박 시계열이 비어 있으면 평균 심박수는 0이다")
    func averageHeartRate_returnsZero_whenSamplesEmpty() {
        // Given
        let expectedValue = 0
        let workout = makeDetailedWorkout(heartRateSamples: [])

        // When
        let result = workout.averageHeartRate

        // Then
        #expect(result == expectedValue)
    }

    @Test("케이던스 시계열이 비어 있으면 평균 케이던스는 0이다")
    func averageCadence_returnsZero_whenSamplesEmpty() {
        // Given
        let expectedValue = 0
        let workout = makeDetailedWorkout(cadenceSamples: [])

        // When
        let result = workout.averageCadence

        // Then
        #expect(result == expectedValue)
    }

    @Test("수직 진폭 시계열이 비어 있으면 0이다")
    func runningVerticalOscillation_returnsZero_whenSamplesEmpty() {
        // Given
        let expectedValue = 0.0
        let workout = makeDetailedWorkout(runningVerticalOscillationSamples: [])

        // When
        let result = workout.runningVerticalOscillation

        // Then
        #expect(result == expectedValue)
    }

    @Test("지면 접촉 시간 시계열이 비어 있으면 0이다")
    func runningGroundContactTime_returnsZero_whenSamplesEmpty() {
        // Given
        let expectedValue = 0.0
        let workout = makeDetailedWorkout(runningGroundContactTimeSamples: [])

        // When
        let result = workout.runningGroundContactTime

        // Then
        #expect(result == expectedValue)
    }

    @Test("보폭 시계열이 비어 있으면 0이다")
    func walkingStepLength_returnsZero_whenSamplesEmpty() {
        // Given
        let expectedValue = 0.0
        let workout = makeDetailedWorkout(walkingStepLengthSamples: [])

        // When
        let result = workout.walkingStepLength

        // Then
        #expect(result == expectedValue)
    }

    @Test("러닝 파워 시계열이 비어 있으면 0이다")
    func runningPower_returnsZero_whenSamplesEmpty() {
        // Given
        let expectedValue = 0.0
        let workout = makeDetailedWorkout(runningPowerSamples: [])

        // When
        let result = workout.runningPower

        // Then
        #expect(result == expectedValue)
    }

    @Test("러닝 보폭 시계열이 비어 있으면 0이다")
    func runningStrideLength_returnsZero_whenSamplesEmpty() {
        // Given
        let expectedValue = 0.0
        let workout = makeDetailedWorkout(runningStrideLengthSamples: [])

        // When
        let result = workout.runningStrideLength

        // Then
        #expect(result == expectedValue)
    }

    // MARK: - 산술평균 산출

    @Test("수직 진폭은 샘플의 산술평균을 반환한다")
    func runningVerticalOscillation_returnsArithmeticMean_whenSamplesExist() {
        // Given
        let expectedValue = 8.4
        let workout = makeDetailedWorkout(
            runningVerticalOscillationSamples: makeSamples([8.0, 8.8])
        )

        // When
        let result = workout.runningVerticalOscillation

        // Then
        #expect(abs(result - expectedValue) < 0.000_001)
    }

    @Test("지면 접촉 시간은 샘플의 산술평균을 반환한다")
    func runningGroundContactTime_returnsArithmeticMean_whenSamplesExist() {
        // Given
        let expectedValue = 245.0
        let workout = makeDetailedWorkout(
            runningGroundContactTimeSamples: makeSamples([240.0, 250.0])
        )

        // When
        let result = workout.runningGroundContactTime

        // Then
        #expect(result == expectedValue)
    }

    @Test("보폭은 샘플의 산술평균을 반환한다")
    func walkingStepLength_returnsArithmeticMean_whenSamplesExist() {
        // Given
        let expectedValue = 1.12
        let workout = makeDetailedWorkout(
            walkingStepLengthSamples: makeSamples([1.10, 1.14])
        )

        // When
        let result = workout.walkingStepLength

        // Then
        #expect(abs(result - expectedValue) < 0.000_001)
    }

    @Test("러닝 파워는 샘플의 산술평균을 반환한다")
    func runningPower_returnsArithmeticMean_whenSamplesExist() {
        // Given
        let expectedValue = 300.0
        let workout = makeDetailedWorkout(
            runningPowerSamples: makeSamples([280.0, 320.0])
        )

        // When
        let result = workout.runningPower

        // Then
        #expect(result == expectedValue)
    }

    @Test("러닝 보폭은 샘플의 산술평균을 반환한다")
    func runningStrideLength_returnsArithmeticMean_whenSamplesExist() {
        // Given
        let expectedValue = 1.35
        let workout = makeDetailedWorkout(
            runningStrideLengthSamples: makeSamples([1.30, 1.40])
        )

        // When
        let result = workout.runningStrideLength

        // Then
        #expect(result == expectedValue)
    }

    // MARK: - 버림 규칙 (Int 지표)

    @Test("심박 평균의 소수부는 반올림하지 않고 버린다")
    func averageHeartRate_truncatesFraction_whenAverageHasFraction() {
        // Given
        let expectedValue = 150    // (150.0 + 151.9) / 2 = 150.95 → 버림 150
        let workout = makeDetailedWorkout(heartRateSamples: makeSamples([150.0, 151.9]))

        // When
        let result = workout.averageHeartRate

        // Then
        #expect(result == expectedValue)
    }

    @Test("케이던스 평균의 소수부는 반올림하지 않고 버린다")
    func averageCadence_truncatesFraction_whenAverageHasFraction() {
        // Given
        let expectedValue = 170    // (170.0 + 171.8) / 2 = 170.9 → 버림 170
        let workout = makeDetailedWorkout(cadenceSamples: makeSamples([170.0, 171.8]))

        // When
        let result = workout.averageCadence

        // Then
        #expect(result == expectedValue)
    }

    // MARK: - 평균 정의 (가중치 없음 / 지표 독립)

    @Test("샘플 간격이 불균등해도 시간 가중이 아닌 산술평균이다")
    func average_ignoresOffsetSec_whenSampleIntervalsAreUneven() {
        // Given
        let expectedValue = 200.0
        let samples = [
            MetricSample(offsetSec: 0, value: 100),
            MetricSample(offsetSec: 1, value: 200),
            MetricSample(offsetSec: 1000, value: 300),
        ]
        let workout = makeDetailedWorkout(runningPowerSamples: samples)

        // When
        let result = workout.runningPower

        // Then
        #expect(result == expectedValue)
    }

    @Test("한 지표만 채워도 다른 지표의 평균은 0이다")
    func average_isIndependentPerMetric_whenOnlyOneSeriesIsPopulated() {
        // Given
        let expectedPower = 300.0
        let expectedCadence = 0
        let workout = makeDetailedWorkout(runningPowerSamples: makeSamples([300.0]))

        // When & Then
        #expect(workout.runningPower == expectedPower)
        #expect(workout.averageCadence == expectedCadence)
    }

    // MARK: - 스칼라 필드 (파생 아님)

    @Test("비시계열 스칼라 지표는 파생 없이 주입값을 그대로 노출한다")
    func scalarMetrics_areStoredAsGiven() {
        // Given
        let expectedEnergy = 450.0
        let expectedResting = 58.0
        let expectedRecovery = 32.0
        let workout = makeDetailedWorkout(
            activeEnergyBurned: expectedEnergy,
            restingHeartRate: expectedResting,
            heartRateRecoveryOneMinute: expectedRecovery
        )

        // When & Then
        #expect(workout.activeEnergyBurned == expectedEnergy)
        #expect(workout.restingHeartRate == expectedResting)
        #expect(workout.heartRateRecoveryOneMinute == expectedRecovery)
    }
}

// MARK: - Helpers

private extension DetailedWorkoutTests {
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

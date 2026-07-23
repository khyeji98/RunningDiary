@testable import Models
import Testing

@Suite("MetricSample.average")
struct MetricSampleAverageTests {

    @Test("샘플이 비어 있으면 nil")
    func average_isNil_whenEmpty() {
        let result = MetricSample.average(of: [])
        #expect(result == nil)
    }

    @Test("단일 샘플이면 그 값")
    func average_isValue_whenSingleSample() {
        let expected = 155.0
        let samples = [MetricSample(offsetSec: 0, value: expected)]

        let result = MetricSample.average(of: samples)

        #expect(result == expected)
    }

    @Test("여러 샘플이면 offsetSec 가중치 없이 산술평균")
    func average_isArithmeticMean_ignoringOffset() {
        let expected = 151.0
        let samples = [
            MetricSample(offsetSec: 0, value: 150.0),
            MetricSample(offsetSec: 999, value: 152.0),
        ]

        let result = MetricSample.average(of: samples)

        #expect(result == expected)
    }

    @Test("Int 변환 시 소수부를 버린다(반올림 아님)")
    func average_toInt_truncatesFraction() {
        let expected = 150
        let samples = [
            MetricSample(offsetSec: 0, value: 150.0),
            MetricSample(offsetSec: 1, value: 151.9),
        ]

        let result = MetricSample.average(of: samples).map(Int.init)

        #expect(result == expected)
    }
}

import Foundation
@testable import HealthKitService
import Testing

// MARK: - HealthKitError Tests

@Suite("HealthKitError Tests")
struct HealthKitErrorTests {
    @Test("HealthKitError cases are equatable")
    func testEquatable() {
        #expect(HealthKitError.notAvailable == HealthKitError.notAvailable)
        #expect(HealthKitError.authorizationFailed == HealthKitError.authorizationFailed)
        #expect(HealthKitError.dataNotFound == HealthKitError.dataNotFound)

        #expect(HealthKitError.notAvailable != HealthKitError.authorizationFailed)
        #expect(HealthKitError.notAvailable != HealthKitError.dataNotFound)
        #expect(HealthKitError.authorizationFailed != HealthKitError.dataNotFound)
    }
}

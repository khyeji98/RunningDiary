//
//  DataMapperTests.swift
//  RunDiaryTests
//

import Foundation
import Testing

@testable import RunDiary

@Suite("DataMapper")
struct DataMapperTests {

    private struct SampleModel: Codable, Equatable {
        let name: String
        let value: Int
    }

    // MARK: - encode

    @Test("encode: Encodable → Data 성공")
    func encode_succeeds() throws {
        let model = SampleModel(name: "test", value: 42)
        let data = try DataMapper.encode(from: model)
        #expect(!data.isEmpty)
    }

    // MARK: - decode

    @Test("decode: Data → Decodable 성공")
    func decode_succeeds() throws {
        let original = SampleModel(name: "hello", value: 7)
        let data = try DataMapper.encode(from: original)
        let decoded: SampleModel = try DataMapper.decode(from: data)
        #expect(decoded == original)
    }

    // MARK: - round-trip

    @Test("round-trip: encode → decode 동일값 복원")
    func roundTrip_preservesValue() throws {
        let original = SampleModel(name: "런다이어리", value: 2025)
        let data = try DataMapper.encode(from: original)
        let decoded: SampleModel = try DataMapper.decode(from: data)
        #expect(decoded == original)
    }

    // MARK: - error

    @Test("decode: 잘못된 Data → throws")
    func decode_invalidData_throws() {
        let garbage = Data([0x00, 0xFF, 0x42])
        #expect(throws: (any Error).self) {
            let _: SampleModel = try DataMapper.decode(from: garbage)
        }
    }
}

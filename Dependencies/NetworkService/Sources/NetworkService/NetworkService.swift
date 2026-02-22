
import Foundation
import SimpleNetwork

public struct RunDiaryNetworkService {
    public init() {}
    
    public func fetchNotice() async throws -> String {
        // SimpleNetwork 라이브러리 연동 예시 (실제 호출은 하지 않음)
        // let endpoint = Endpoint<String>(path: "/notice", method: .get)
        // return try await NetworkService.shared.request(endpoint)
        return "공지사항: SimpleNetwork 연동 테스트 중입니다."
    }
}

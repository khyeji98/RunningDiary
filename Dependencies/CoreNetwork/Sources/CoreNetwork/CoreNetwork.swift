import SimpleNetwork

public final class CoreNetwork {

    public static let shared = CoreNetwork()

    public lazy var session: URLSessionService = URLSessionService()

    private init() {}
}

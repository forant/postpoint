import Foundation

enum APIConfig {
    /// Base URL for the PostPoint backend.
    /// Debug builds hit localhost; release builds (TestFlight / App Store) hit Render.
    static var baseURL: String {
        #if DEBUG
        return "http://localhost:8000"
        #else
        return "https://postpoint-rxte.onrender.com"
        #endif
    }

    /// Full URL for the debrief endpoint
    static var debriefURL: URL {
        URL(string: "\(baseURL)/debrief")!
    }
}

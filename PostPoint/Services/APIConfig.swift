import Foundation

enum APIConfig {
    /// Base URL for the PostPoint backend.
    /// Set this to your Render deployment URL before shipping.
    /// Falls back to localhost for local development.
    static var baseURL: String {
        // 1. Check for override in Secrets.plist (useful for staging vs prod)
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let url = dict["BACKEND_URL"] as? String,
           !url.isEmpty, url != "YOUR_URL_HERE" {
            return url
        }

        // 2. Check environment variable
        if let url = ProcessInfo.processInfo.environment["POSTPOINT_BACKEND_URL"],
           !url.isEmpty {
            return url
        }

        // 3. Default to localhost for development
        return "http://localhost:8000"
    }

    /// Full URL for the debrief endpoint
    static var debriefURL: URL {
        URL(string: "\(baseURL)/debrief")!
    }
}

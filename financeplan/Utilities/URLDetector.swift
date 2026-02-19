import Foundation

/// Utility for detecting and extracting URLs from text
struct URLDetector {
    /// Detects all valid URLs in the given text
    /// - Parameter text: The text to search for URLs
    /// - Returns: Array of detected URLs
    static func detectURLs(in text: String) -> [URL] {
        guard !text.isEmpty else { return [] }

        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

        var urls: [URL] = []
        matches?.forEach { match in
            if let url = match.url, isValidPreviewURL(url) {
                urls.append(url)
            }
        }

        return urls
    }

    /// Detects the first valid URL in the given text
    /// - Parameter text: The text to search for a URL
    /// - Returns: The first detected URL, or nil if none found
    static func detectFirstURL(in text: String) -> URL? {
        detectURLs(in: text).first
    }

    /// Validates if a URL is suitable for link preview
    /// - Parameter url: The URL to validate
    /// - Returns: True if the URL is valid for preview
    private static func isValidPreviewURL(_ url: URL) -> Bool {
        // Must have http or https scheme
        guard let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            return false
        }

        // Must have a host
        guard let host = url.host, !host.isEmpty else {
            return false
        }

        // Exclude common image/media file extensions
        let excludedExtensions = ["jpg", "jpeg", "png", "gif", "webp", "mp4", "mov", "avi", "pdf"]
        let pathExtension = url.pathExtension.lowercased()
        if excludedExtensions.contains(pathExtension) {
            return false
        }

        return true
    }

    /// Extracts domain name from URL
    /// - Parameter url: The URL to extract domain from
    /// - Returns: Clean domain name (e.g., "news.com.au")
    static func extractDomain(from url: URL) -> String {
        guard let host = url.host else { return "" }
        // Remove "www." prefix if present
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }

    /// Removes all URLs from the given text
    /// - Parameter text: The text to remove URLs from
    /// - Returns: Text with URLs removed, trimmed of extra whitespace
    static func removeURLs(from text: String) -> String {
        guard !text.isEmpty else { return text }

        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

        var result = text
        // Process matches in reverse order to maintain string indices
        matches?.reversed().forEach { match in
            if let range = Range(match.range, in: text),
               let url = match.url,
               isValidPreviewURL(url) {
                result.removeSubrange(range)
            }
        }

        // Clean up extra whitespace
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

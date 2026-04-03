import Foundation
import SwiftData
import StockPlanShared

@Model
final class SDWatchlistItem {
    @Attribute(.unique) var id: String
    var symbol: String
    var note: String?
    var status: String
    var nextReviewAt: String?
    var lastSyncedAt: Date?

    init(id: String, symbol: String, note: String? = nil, status: String, nextReviewAt: String? = nil) {
        self.id = id
        self.symbol = symbol
        self.note = note
        self.status = status
        self.nextReviewAt = nextReviewAt
        self.lastSyncedAt = Date()
    }

    init(from response: WatchlistItemResponse) {
        self.id = response.id
        self.symbol = response.symbol
        self.note = response.note
        self.status = response.status.rawValue
        self.nextReviewAt = response.nextReviewAt
        self.lastSyncedAt = Date()
    }

    func update(from response: WatchlistItemResponse) {
        self.symbol = response.symbol
        self.note = response.note
        self.status = response.status.rawValue
        self.nextReviewAt = response.nextReviewAt
        self.lastSyncedAt = Date()
    }
}

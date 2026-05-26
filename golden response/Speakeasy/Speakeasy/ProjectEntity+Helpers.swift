import Foundation
import CoreData

extension ProjectEntity {
    var sortedImages: [ProjectImageEntity] {
        ((images?.allObjects as? [ProjectImageEntity]) ?? [])
            .sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
    }

    var imageCount: Int {
        sortedImages.count
    }

    var coverImageEntity: ProjectImageEntity? {
        sortedImages.first
    }
}

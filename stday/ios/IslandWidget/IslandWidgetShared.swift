import Foundation
import WidgetKit

struct IslandWidgetConstants {
    static let appGroupId = "group.com.xiaoerlcx.app.island"
    static let payloadKey = "island_widget_payload"
    static let urlScheme = "stday"
}

struct IslandWidgetTaskItem: Identifiable, Codable {
    let id: String
    let islandId: String
    let title: String
    let date: String
    let status: String

    var isDone: Bool { status == "done" }
}

struct IslandWidgetPayload: Codable {
    let currentIslandId: String
    let islandName: String
    let islandStatus: String
    let todayDate: String
    let completed: Int
    let total: Int
    let todayTasks: [IslandWidgetTaskItem]
    let islandIndex: Int?
    let islandTotal: Int?
    let isGrowthMain: Bool?
    let displayLevel: Int?
    let categoryId: String?
    let buildingPreviewLevel: Int?
    let buildingThumbPath: String?

    var canGoPrev: Bool { (islandTotal ?? 1) > 1 }
    var canGoNext: Bool { (islandTotal ?? 1) > 1 }
    var isMainIsland: Bool { isGrowthMain ?? false }
    var levelLabel: String { "Lv.\(displayLevel ?? 0)" }
    var showBuildingThumb: Bool {
        !(isGrowthMain ?? false) && (buildingPreviewLevel ?? 0) > 0
    }

    static let placeholder = IslandWidgetPayload(
        currentIslandId: "",
        islandName: "星屿",
        islandStatus: "平静",
        todayDate: "",
        completed: 0,
        total: 0,
        todayTasks: [],
        islandIndex: 0,
        islandTotal: 1,
        isGrowthMain: false,
        displayLevel: 0,
        categoryId: "",
        buildingPreviewLevel: 0,
        buildingThumbPath: nil
    )
}

struct IslandEntry: TimelineEntry {
    let date: Date
    let payload: IslandWidgetPayload
}

enum IslandWidgetDataStore {
    static func loadPayload() -> IslandWidgetPayload {
        guard
            let defaults = UserDefaults(suiteName: IslandWidgetConstants.appGroupId),
            let raw = defaults.string(forKey: IslandWidgetConstants.payloadKey),
            !raw.isEmpty,
            let data = raw.data(using: .utf8),
            let payload = try? JSONDecoder().decode(IslandWidgetPayload.self, from: data),
            !payload.currentIslandId.isEmpty
        else {
            return .placeholder
        }
        return payload
    }

    static func islandURL(islandId: String) -> URL {
        URL(string: "\(IslandWidgetConstants.urlScheme)://widget/island?islandId=\(islandId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? islandId)")!
    }

    static func taskURL(islandId: String, taskId: String) -> URL {
        let island = islandId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? islandId
        let task = taskId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? taskId
        return URL(string: "\(IslandWidgetConstants.urlScheme)://widget/task?islandId=\(island)&taskId=\(task)")!
    }

    static func quickRecordURL(islandId: String) -> URL {
        URL(string: "\(IslandWidgetConstants.urlScheme)://widget/quick-record?islandId=\(islandId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? islandId)")!
    }

    static func cycleURL(direction: String) -> URL {
        URL(string: "\(IslandWidgetConstants.urlScheme)://widget/cycle?direction=\(direction)")!
    }
}

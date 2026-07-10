import Foundation
import AppIntents
import WidgetKit

struct IslandWidgetConstants {
    static let appGroupId = "group.com.xiaoerlcx.app.island"
    static let payloadKey = "island_widget_payload"
    static let catalogKey = "island_widget_catalog"
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
    let reviewTitle: String?
    let reviewBody: String?
    let focusLabel: String?
    let todayMomentCount: Int?

    var canGoPrev: Bool { (islandTotal ?? 1) > 1 }
    var canGoNext: Bool { (islandTotal ?? 1) > 1 }
    var isMainIsland: Bool { isGrowthMain ?? false }
    var levelLabel: String { "Lv.\(displayLevel ?? 0)" }
    var safeReviewTitle: String {
        let value = (reviewTitle ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !value.isEmpty { return value }
        return isMainIsland ? "星屿今日回顾" : "\(islandName)今日回顾"
    }
    var safeReviewBody: String {
        let value = (reviewBody ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !value.isEmpty { return value }
        return "写下今天的一件小事，小岛会把它整理成你的成长轨迹。"
    }
    var safeFocusLabel: String {
        let value = (focusLabel ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !value.isEmpty { return value }
        return isMainIsland ? "主岛总览 · 所有日常都会汇入这里" : "\(islandName) · \(levelLabel)"
    }
    var recordedLabel: String {
        let count = todayMomentCount ?? 0
        return count > 0 ? "已记录 \(count) 篇" : "今日未记录"
    }
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
        buildingThumbPath: nil,
        reviewTitle: "星屿今日回顾",
        reviewBody: "写下今天的一件小事，小岛会把它整理成你的成长轨迹。",
        focusLabel: "主岛总览 · 所有日常都会汇入这里",
        todayMomentCount: 0
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

    static func loadCatalog() -> [IslandWidgetPayload] {
        guard
            let defaults = UserDefaults(suiteName: IslandWidgetConstants.appGroupId),
            let raw = defaults.string(forKey: IslandWidgetConstants.catalogKey),
            !raw.isEmpty,
            let data = raw.data(using: .utf8),
            let catalog = try? JSONDecoder().decode([IslandWidgetPayload].self, from: data)
        else {
            return []
        }
        return catalog.filter { !$0.currentIslandId.isEmpty }
    }

    static func cyclePayload(direction: String) {
        let catalog = loadCatalog()
        guard !catalog.isEmpty else { return }

        let current = loadPayload()
        let currentIndex = catalog.firstIndex {
            $0.currentIslandId == current.currentIslandId
        } ?? 0
        let delta = direction == "prev" ? -1 : 1
        let nextIndex = (currentIndex + delta + catalog.count) % catalog.count
        let next = catalog[nextIndex]

        guard
            let defaults = UserDefaults(suiteName: IslandWidgetConstants.appGroupId),
            let data = try? JSONEncoder().encode(next),
            let raw = String(data: data, encoding: .utf8)
        else {
            return
        }

        defaults.set(raw, forKey: IslandWidgetConstants.payloadKey)
        WidgetCenter.shared.reloadTimelines(ofKind: "IslandQuickTaskWidget")
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

@available(iOS 17.0, *)
struct CycleIslandWidgetIntent: AppIntent {
    static var title: LocalizedStringResource = "切换岛屿"
    static var openAppWhenRun: Bool = false

    @Parameter(title: "方向")
    var direction: String

    init() {
        direction = "next"
    }

    init(direction: String) {
        self.direction = direction
    }

    func perform() async throws -> some IntentResult {
        IslandWidgetDataStore.cyclePayload(direction: direction)
        return .result()
    }
}

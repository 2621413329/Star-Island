import SwiftUI
import WidgetKit

struct IslandProvider: TimelineProvider {
    func placeholder(in context: Context) -> IslandEntry {
        IslandEntry(date: Date(), payload: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (IslandEntry) -> Void) {
        completion(IslandEntry(date: Date(), payload: IslandWidgetDataStore.loadPayload()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<IslandEntry>) -> Void) {
        let entry = IslandEntry(date: Date(), payload: IslandWidgetDataStore.loadPayload())
        let next = Calendar.current.date(byAdding: .minute, value: 5, to: Date()) ?? Date().addingTimeInterval(300)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct IslandQuickTaskWidgetEntryView: View {
    let entry: IslandEntry

    private var payload: IslandWidgetPayload { entry.payload }
    private var hasIsland: Bool { !payload.currentIslandId.isEmpty }

    var body: some View {
        ZStack {
            IslandWidgetBackground()

            if hasIsland {
                content
                    .widgetURL(IslandWidgetDataStore.islandURL(islandId: payload.currentIslandId))
            } else {
                emptyState
            }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Text("今日待办")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(red: 0.10, green: 0.28, blue: 0.45))

                Spacer(minLength: 6)

                WidgetTodoProgressRing(
                    completed: payload.completed,
                    total: max(payload.total, payload.todayTasks.count)
                )
            }

            islandSwitcherRow
                .padding(.top, 4)

            taskList
                .padding(.top, 4)

            Spacer(minLength: 0)

            quickRecordButton
                .padding(.top, 4)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private var islandSwitcherRow: some View {
        HStack(spacing: 2) {
            if payload.canGoPrev {
                Link(destination: IslandWidgetDataStore.cycleURL(direction: "prev")) {
                    Text("‹")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(red: 0.35, green: 0.52, blue: 0.66))
                        .frame(width: 18, height: 18)
                }
            }

            Link(destination: IslandWidgetDataStore.islandURL(islandId: payload.currentIslandId)) {
                HStack(spacing: 4) {
                    if payload.showBuildingThumb {
                        WidgetIslandBuildingThumb(path: payload.buildingThumbPath)
                    }
                    Text(payload.isMainIsland ? "🏝 \(payload.islandName)" : payload.islandName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color(red: 0.35, green: 0.52, blue: 0.66))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            WidgetIslandLevelBadge(label: payload.levelLabel)

            if payload.canGoNext {
                Link(destination: IslandWidgetDataStore.cycleURL(direction: "next")) {
                    Text("›")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(red: 0.35, green: 0.52, blue: 0.66))
                        .frame(width: 18, height: 18)
                }
            }
        }
    }

    private var taskList: some View {
        VStack(alignment: .leading, spacing: 3) {
            if payload.todayTasks.isEmpty {
                Text("暂无今日任务")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(red: 0.48, green: 0.60, blue: 0.72))
            } else {
                ForEach(payload.todayTasks.prefix(3)) { task in
                    Link(destination: IslandWidgetDataStore.taskURL(islandId: task.islandId, taskId: task.id)) {
                        WidgetTodoTaskRow(title: task.title, isDone: task.isDone)
                    }
                }
            }
        }
    }

    private var quickRecordButton: some View {
        Link(destination: IslandWidgetDataStore.quickRecordURL(islandId: payload.currentIslandId)) {
            HStack(spacing: 4) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 10))
                Text("记录今日日常")
                    .font(.system(size: 11, weight: .semibold))
            }
            .frame(maxWidth: .infinity, minHeight: 28)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.55))
            )
            .foregroundStyle(Color(red: 0.10, green: 0.35, blue: 0.59))
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("今日待办")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(red: 0.10, green: 0.28, blue: 0.45))
                Spacer()
                WidgetTodoProgressRing(completed: 0, total: 0)
            }
            Text("打开 App 选择岛屿")
                .font(.system(size: 11))
                .foregroundStyle(Color(red: 0.48, green: 0.60, blue: 0.72))
                .padding(.top, 8)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }
}

struct IslandQuickTaskWidget: Widget {
    let kind: String = "IslandQuickTaskWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: IslandProvider()) { entry in
            IslandQuickTaskWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    IslandWidgetBackground()
                }
        }
        .configurationDisplayName("岛屿快捷任务")
        .description("展示当前岛屿的今日待办，并提供快速记录入口。")
        .supportedFamilies([.systemMedium])
    }
}

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
        VStack(alignment: .leading, spacing: 8) {
            Link(destination: IslandWidgetDataStore.islandURL(islandId: payload.currentIslandId)) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("🏝 \(payload.islandName)")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color(red: 0.12, green: 0.28, blue: 0.42))
                        .lineLimit(1)

                    Text(payload.islandStatus)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color(red: 0.28, green: 0.52, blue: 0.66).opacity(0.88))
                }
            }

            Text("今日任务 \(payload.completed)/\(payload.total)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(red: 0.16, green: 0.34, blue: 0.48))

            VStack(alignment: .leading, spacing: 4) {
                if payload.todayTasks.isEmpty {
                    Text("暂无今日任务")
                        .font(.caption)
                        .foregroundStyle(Color(red: 0.28, green: 0.48, blue: 0.58).opacity(0.82))
                } else {
                    ForEach(payload.todayTasks.prefix(3)) { task in
                        Link(destination: IslandWidgetDataStore.taskURL(islandId: task.islandId, taskId: task.id)) {
                            HStack(spacing: 6) {
                                Text(task.isDone ? "✓" : "•")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(task.isDone
                                        ? Color(red: 0.22, green: 0.62, blue: 0.48)
                                        : Color(red: 0.34, green: 0.56, blue: 0.68))
                                Text(task.title)
                                    .font(.caption)
                                    .foregroundStyle(Color(red: 0.18, green: 0.36, blue: 0.46))
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }

            Spacer(minLength: 0)

            Link(destination: IslandWidgetDataStore.quickRecordURL(islandId: payload.currentIslandId)) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("快速记录")
                        .font(.footnote.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.58))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.72), lineWidth: 1)
                )
                .foregroundStyle(Color(red: 0.12, green: 0.38, blue: 0.52))
            }
        }
        .padding(14)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🏝 星屿")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color(red: 0.12, green: 0.28, blue: 0.42))
            Text("打开 App 选择岛屿")
                .font(.caption)
                .foregroundStyle(Color(red: 0.28, green: 0.48, blue: 0.58))
            Spacer()
            Text("+ 快速记录")
                .font(.footnote.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.45))
                )
                .foregroundStyle(Color(red: 0.12, green: 0.38, blue: 0.52).opacity(0.72))
        }
        .padding(14)
    }
}

struct IslandWidgetBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.78, green: 0.92, blue: 0.98, opacity: 0.92),
                Color(red: 0.62, green: 0.84, blue: 0.92, opacity: 0.88),
                Color(red: 0.48, green: 0.72, blue: 0.86, opacity: 0.84),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .fill(Color.white.opacity(0.12))
        )
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
        .description("展示当前岛屿的今日任务，并提供快速记录入口。")
        .supportedFamilies([.systemMedium])
    }
}

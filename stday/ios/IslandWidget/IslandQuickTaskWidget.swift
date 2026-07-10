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
            headerRow

            reviewCard

            bottomRow
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var headerRow: some View {
        HStack(alignment: .center, spacing: 8) {
            if payload.canGoPrev {
                islandSwitchButton(title: "‹", direction: "prev")
            }

            Link(destination: IslandWidgetDataStore.islandURL(islandId: payload.currentIslandId)) {
                HStack(spacing: 4) {
                    Text(payload.isMainIsland ? "主岛回顾" : payload.islandName)
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(red: 0.10, green: 0.28, blue: 0.45))
                        .lineLimit(1)
                    WidgetIslandLevelBadge(label: payload.levelLabel)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text(payload.recordedLabel)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.23, green: 0.50, blue: 0.64))
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.62))
                )

            if payload.canGoNext {
                islandSwitchButton(title: "›", direction: "next")
            }
        }
    }

    private func islandSwitchButton(title: String, direction: String) -> some View {
        Link(destination: IslandWidgetDataStore.cycleURL(direction: direction)) {
            Text(title)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(red: 0.22, green: 0.48, blue: 0.68))
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.56))
                )
                .contentShape(Rectangle())
        }
    }

    private var reviewCard: some View {
        Link(destination: IslandWidgetDataStore.islandURL(islandId: payload.currentIslandId)) {
            HStack(alignment: .center, spacing: 10) {
                if payload.showBuildingThumb {
                    WidgetIslandBuildingThumb(path: payload.buildingThumbPath)
                        .frame(width: 36, height: 36)
                        .padding(6)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.54))
                        )
                } else {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.72, green: 0.88, blue: 0.78),
                                        Color(red: 0.39, green: 0.72, blue: 0.74)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white.opacity(0.92))
                    }
                    .frame(width: 46, height: 46)
                    .shadow(color: Color(red: 0.18, green: 0.45, blue: 0.42).opacity(0.16), radius: 8, y: 4)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(payload.safeReviewTitle)
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(Color(red: 0.10, green: 0.28, blue: 0.45))
                        .lineLimit(1)

                    Text(payload.safeReviewBody)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(red: 0.28, green: 0.42, blue: 0.52))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, minHeight: 78, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.66))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.72), lineWidth: 1)
            )
            .shadow(color: Color(red: 0.19, green: 0.45, blue: 0.60).opacity(0.10), radius: 12, y: 6)
        }
    }

    private var bottomRow: some View {
        HStack(spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "sparkles")
                    .font(.system(size: 10, weight: .bold))
                Text(payload.safeFocusLabel)
                    .font(.system(size: 10, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(Color(red: 0.30, green: 0.49, blue: 0.60))
            .frame(maxWidth: .infinity, alignment: .leading)

            Link(destination: IslandWidgetDataStore.quickRecordURL(islandId: payload.currentIslandId)) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 9, weight: .bold))
                    Text("记录")
                        .font(.system(size: 11, weight: .heavy))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .frame(height: 28)
                .background(
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.25, green: 0.72, blue: 0.68),
                                    Color(red: 0.12, green: 0.53, blue: 0.61)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("星屿今日回顾")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(Color(red: 0.10, green: 0.28, blue: 0.45))
                Spacer()
            }
            Text("打开 App 选择岛屿，写下今天的一件小事。")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(red: 0.28, green: 0.42, blue: 0.52))
                .lineLimit(3)
            Spacer(minLength: 0)
            quickRecordButton
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
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
        .configurationDisplayName("星屿日常回顾")
        .description("展示今日日常回顾、当前关注岛屿，并提供快速记录入口。")
        .supportedFamilies([.systemMedium])
    }
}

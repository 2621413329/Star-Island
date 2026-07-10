import SwiftUI
import WidgetKit
import UIKit

// MARK: - Design tokens

private enum WidgetTodoStyle {
    static let bgTop = Color(red: 0.92, green: 0.96, blue: 1.0)
    static let bgBottom = Color(red: 0.88, green: 0.94, blue: 0.99)
    static let title = Color(red: 0.10, green: 0.28, blue: 0.45)
    static let accent = Color(red: 0.10, green: 0.35, blue: 0.59)
    static let ringTrack = Color(red: 0.78, green: 0.88, blue: 0.96)
    static let taskDone = Color(red: 0.15, green: 0.32, blue: 0.48)
    static let taskTodo = Color(red: 0.48, green: 0.60, blue: 0.72)
    static let islandCaption = Color(red: 0.35, green: 0.52, blue: 0.66)
}

// MARK: - Progress ring

struct WidgetTodoProgressRing: View {
    let completed: Int
    let total: Int

    private var progress: Double {
        guard total > 0 else { return 0 }
        return min(1, Double(completed) / Double(total))
    }

    private var label: String {
        if total <= 0 { return "0/0" }
        return "\(completed)/\(total)"
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(WidgetTodoStyle.ringTrack, lineWidth: 3)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    WidgetTodoStyle.accent,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(WidgetTodoStyle.accent)
                .minimumScaleFactor(0.7)
        }
        .frame(width: 34, height: 34)
    }
}

// MARK: - Task row

struct WidgetTodoTaskRow: View {
    let title: String
    let isDone: Bool

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                if isDone {
                    Circle()
                        .fill(WidgetTodoStyle.accent)
                        .frame(width: 14, height: 14)
                    Image(systemName: "checkmark")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Circle()
                        .stroke(WidgetTodoStyle.ringTrack, lineWidth: 1.5)
                        .frame(width: 14, height: 14)
                }
            }
            .frame(width: 14, height: 14)

            Text(title)
                .font(.system(size: 11, weight: isDone ? .medium : .regular))
                .foregroundStyle(isDone ? WidgetTodoStyle.taskDone : WidgetTodoStyle.taskTodo)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct WidgetIslandLevelBadge: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundStyle(WidgetTodoStyle.accent)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.72))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(WidgetTodoStyle.ringTrack, lineWidth: 1)
            )
    }
}

struct WidgetIslandBuildingThumb: View {
    let path: String?

    var body: some View {
        Group {
            if let path, let image = UIImage(contentsOfFile: path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(width: 22, height: 22)
    }
}

// MARK: - Background

struct IslandWidgetBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [WidgetTodoStyle.bgTop, WidgetTodoStyle.bgBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(0.34))
                .frame(width: 130, height: 130)
                .offset(x: 112, y: -58)

            Circle()
                .fill(Color(red: 0.34, green: 0.75, blue: 0.77).opacity(0.18))
                .frame(width: 180, height: 180)
                .offset(x: -116, y: 82)

            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(Color(red: 0.36, green: 0.70, blue: 0.54).opacity(0.16))
                .frame(width: 220, height: 42)
                .rotationEffect(.degrees(-4))
                .offset(x: 40, y: 64)
        }
    }
}

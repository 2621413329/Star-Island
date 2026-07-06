package com.stday.stday

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject

class IslandWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val payload = parsePayload(widgetData.getString(PAYLOAD_KEY, null))
        appWidgetIds.forEach { widgetId ->
            appWidgetManager.updateAppWidget(
                widgetId,
                buildRemoteViews(context, payload),
            )
        }
    }

    private fun buildRemoteViews(
        context: Context,
        payload: WidgetPayload,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_island)
        val hasIsland = payload.currentIslandId.isNotEmpty()

        if (!hasIsland) {
            views.setTextViewText(R.id.island_title, "🏝 星屿")
            views.setTextViewText(R.id.island_status, "")
            views.setTextViewText(R.id.task_progress, "打开 App 选择岛屿")
            hideTaskRows(views)
            views.setViewVisibility(R.id.task_empty, View.GONE)
            views.setViewVisibility(R.id.quick_add, View.VISIBLE)
            views.setTextViewText(
                R.id.quick_add,
                context.getString(R.string.widget_island_quick_record),
            )
            val launchIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
            )
            views.setOnClickPendingIntent(R.id.widget_root, launchIntent)
            views.setOnClickPendingIntent(R.id.quick_add, launchIntent)
            return views
        }

        views.setTextViewText(R.id.island_title, "🏝 ${payload.islandName}")
        views.setTextViewText(R.id.island_status, payload.islandStatus)
        views.setTextViewText(
            R.id.task_progress,
            "今日任务 ${payload.completed}/${payload.total}",
        )

        val taskViews = listOf(R.id.task1, R.id.task2, R.id.task3)
        val tasks = payload.tasks.take(MAX_TASKS)
        if (tasks.isEmpty()) {
            hideTaskRows(views)
            views.setViewVisibility(R.id.task_empty, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.task_empty, View.GONE)
            tasks.forEachIndexed { index, task ->
                val viewId = taskViews[index]
                val prefix = if (task.isDone) "✓ " else "• "
                views.setTextViewText(viewId, "$prefix${task.title}")
                views.setViewVisibility(viewId, View.VISIBLE)
                views.setOnClickPendingIntent(
                    viewId,
                    launchDeepLink(
                        context,
                        buildTaskUri(payload.currentIslandId, task.id),
                    ),
                )
            }
            for (index in tasks.size until MAX_TASKS) {
                views.setViewVisibility(taskViews[index], View.GONE)
            }
        }

        views.setOnClickPendingIntent(
            R.id.island_header,
            launchDeepLink(
                context,
                buildIslandUri(payload.currentIslandId),
            ),
        )
        views.setOnClickPendingIntent(
            R.id.widget_root,
            launchDeepLink(
                context,
                buildIslandUri(payload.currentIslandId),
            ),
        )
        views.setOnClickPendingIntent(
            R.id.quick_add,
            launchDeepLink(
                context,
                buildQuickRecordUri(payload.currentIslandId),
            ),
        )

        return views
    }

    private fun hideTaskRows(views: RemoteViews) {
        views.setViewVisibility(R.id.task1, View.GONE)
        views.setViewVisibility(R.id.task2, View.GONE)
        views.setViewVisibility(R.id.task3, View.GONE)
    }

    private fun launchDeepLink(context: Context, uri: Uri) =
        HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, uri)

    private fun buildIslandUri(islandId: String) =
        Uri.parse("stday://widget/island?islandId=${Uri.encode(islandId)}")

    private fun buildTaskUri(islandId: String, taskId: String) =
        Uri.parse(
            "stday://widget/task?islandId=${Uri.encode(islandId)}&taskId=${Uri.encode(taskId)}",
        )

    private fun buildQuickRecordUri(islandId: String) =
        Uri.parse("stday://widget/quick-record?islandId=${Uri.encode(islandId)}")

    private fun parsePayload(raw: String?): WidgetPayload {
        if (raw.isNullOrBlank()) return WidgetPayload.empty()
        return try {
            val json = JSONObject(raw)
            val islandId = json.optString("currentIslandId", "")
            if (islandId.isBlank()) return WidgetPayload.empty()

            val tasksJson = json.optJSONArray("todayTasks") ?: JSONArray()
            val tasks = buildList {
                for (index in 0 until tasksJson.length()) {
                    val item = tasksJson.optJSONObject(index) ?: continue
                    add(
                        WidgetTask(
                            id = item.optString("id", ""),
                            title = item.optString("title", ""),
                            isDone = item.optString("status", "todo") == "done",
                        ),
                    )
                }
            }

            WidgetPayload(
                currentIslandId = islandId,
                islandName = json.optString("islandName", "岛屿"),
                islandStatus = json.optString("islandStatus", "平静"),
                completed = json.optInt("completed", 0),
                total = json.optInt("total", 0),
                tasks = tasks,
            )
        } catch (_: Exception) {
            WidgetPayload.empty()
        }
    }

    private data class WidgetPayload(
        val currentIslandId: String,
        val islandName: String,
        val islandStatus: String,
        val completed: Int,
        val total: Int,
        val tasks: List<WidgetTask>,
    ) {
        companion object {
            fun empty() = WidgetPayload("", "星屿", "平静", 0, 0, emptyList())
        }
    }

    private data class WidgetTask(
        val id: String,
        val title: String,
        val isDone: Boolean,
    )

    companion object {
        private const val PAYLOAD_KEY = "island_widget_payload"
        private const val MAX_TASKS = 3
    }
}

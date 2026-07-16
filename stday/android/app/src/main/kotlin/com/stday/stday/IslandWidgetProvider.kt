package com.stday.stday

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.net.Uri
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import kotlin.math.min

class IslandWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        scheduleMidnightRefresh(context)
        val rawPayload = parsePayload(widgetData.getString(PAYLOAD_KEY, null))
        val payload = rawPayload.forCurrentCalendarDay()
        // 跨日后把空态写回，避免下次仍读到昨日任务/记录。
        if (payload.todayDate != rawPayload.todayDate ||
            payload.tasks.size != rawPayload.tasks.size ||
            payload.completed != rawPayload.completed ||
            payload.total != rawPayload.total
        ) {
            persistRolloverPayload(context, payload)
        }
        appWidgetIds.forEach { widgetId ->
            appWidgetManager.updateAppWidget(
                widgetId,
                buildRemoteViews(context, payload, widgetData),
            )
        }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        scheduleMidnightRefresh(context)
    }

    override fun onDisabled(context: Context) {
        cancelMidnightRefresh(context)
        super.onDisabled(context)
    }

    private fun buildRemoteViews(
        context: Context,
        payload: WidgetPayload,
        widgetData: SharedPreferences,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_island)
        val hasIsland = payload.currentIslandId.isNotEmpty()
        val displayTotal = if (payload.total > 0) payload.total else payload.tasks.size

        views.setTextViewText(R.id.todo_title, context.getString(R.string.widget_todo_title))
        views.setTextViewText(R.id.progress_text, "${payload.completed}/$displayTotal")
        views.setImageViewBitmap(
            R.id.progress_ring,
            buildProgressRingBitmap(payload.completed, displayTotal),
        )

        if (!hasIsland) {
            views.setTextViewText(R.id.island_title, context.getString(R.string.widget_open_app_hint))
            views.setViewVisibility(R.id.island_prev, View.GONE)
            views.setViewVisibility(R.id.island_next, View.GONE)
            views.setViewVisibility(R.id.island_level_badge, View.GONE)
            views.setViewVisibility(R.id.island_building_thumb, View.GONE)
            hideTaskRows(views)
            views.setViewVisibility(R.id.task_empty, View.VISIBLE)
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

        val islandTitle = if (payload.isGrowthMain) {
            "🏝 ${payload.islandName}"
        } else {
            payload.islandName
        }
        views.setTextViewText(R.id.island_title, islandTitle)
        views.setTextViewText(R.id.island_level_badge, "Lv.${payload.displayLevel}")
        views.setViewVisibility(R.id.island_level_badge, View.VISIBLE)
        bindBuildingThumb(context, views, payload, widgetData)
        views.setViewVisibility(
            R.id.island_prev,
            if (payload.canGoPrev) View.VISIBLE else View.GONE,
        )
        views.setViewVisibility(
            R.id.island_next,
            if (payload.canGoNext) View.VISIBLE else View.GONE,
        )
        if (payload.canGoPrev) {
            views.setOnClickPendingIntent(
                R.id.island_prev,
                cyclePendingIntent(context, "prev"),
            )
        }
        if (payload.canGoNext) {
            views.setOnClickPendingIntent(
                R.id.island_next,
                cyclePendingIntent(context, "next"),
            )
        }
        views.setTextViewText(
            R.id.quick_add,
            context.getString(R.string.widget_island_quick_record),
        )

        val taskRows = listOf(
            TaskRowIds(R.id.task1_row, R.id.task1_check_bg, R.id.task1_check_mark, R.id.task1),
            TaskRowIds(R.id.task2_row, R.id.task2_check_bg, R.id.task2_check_mark, R.id.task2),
            TaskRowIds(R.id.task3_row, R.id.task3_check_bg, R.id.task3_check_mark, R.id.task3),
        )
        val tasks = payload.tasks.take(MAX_TASKS)
        if (tasks.isEmpty()) {
            hideTaskRows(views)
            views.setViewVisibility(R.id.task_empty, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.task_empty, View.GONE)
            tasks.forEachIndexed { index, task ->
                bindTaskRow(views, taskRows[index], task)
                views.setOnClickPendingIntent(
                    taskRows[index].rowId,
                    launchDeepLink(
                        context,
                        buildTaskUri(payload.currentIslandId, task.id),
                    ),
                )
            }
            for (index in tasks.size until MAX_TASKS) {
                views.setViewVisibility(taskRows[index].rowId, View.GONE)
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

    private fun bindTaskRow(
        views: RemoteViews,
        ids: TaskRowIds,
        task: WidgetTask,
    ) {
        views.setViewVisibility(ids.rowId, View.VISIBLE)
        views.setTextViewText(ids.titleId, task.title)
        if (task.isDone) {
            views.setImageViewResource(ids.checkBgId, R.drawable.widget_task_check_done_bg)
            views.setViewVisibility(ids.checkMarkId, View.VISIBLE)
            views.setTextColor(ids.titleId, Color.parseColor("#264F73"))
        } else {
            views.setImageViewResource(ids.checkBgId, R.drawable.widget_task_check_todo)
            views.setViewVisibility(ids.checkMarkId, View.GONE)
            views.setTextColor(ids.titleId, Color.parseColor("#7A96AD"))
        }
    }

    private fun bindBuildingThumb(
        context: Context,
        views: RemoteViews,
        payload: WidgetPayload,
        widgetData: SharedPreferences,
    ) {
        if (payload.isGrowthMain || payload.buildingPreviewLevel <= 0) {
            views.setViewVisibility(R.id.island_building_thumb, View.GONE)
            return
        }

        val thumbPath = payload.buildingThumbPath
            ?: widgetData.getString(BUILDING_THUMB_KEY, null)
        val bitmap = loadBuildingThumbBitmap(context, thumbPath, payload)
        if (bitmap != null) {
            views.setViewVisibility(R.id.island_building_thumb, View.VISIBLE)
            views.setImageViewBitmap(R.id.island_building_thumb, bitmap)
        } else {
            views.setViewVisibility(R.id.island_building_thumb, View.GONE)
        }
    }

    private fun loadBuildingThumbBitmap(
        context: Context,
        thumbPath: String?,
        payload: WidgetPayload,
    ): Bitmap? {
        if (!thumbPath.isNullOrBlank()) {
            BitmapFactory.decodeFile(thumbPath)?.let { return it }
        }
        if (payload.categoryId.isBlank() || payload.buildingPreviewLevel <= 0) {
            return null
        }
        val level = payload.buildingPreviewLevel.coerceIn(1, 10)
        val assetPath =
            "flutter_assets/assets/images/islands/${payload.categoryId}/buildings/" +
                "lv${level.toString().padStart(2, '0')}.png"
        return try {
            context.assets.open(assetPath).use { stream ->
                BitmapFactory.decodeStream(stream)
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun hideTaskRows(views: RemoteViews) {
        views.setViewVisibility(R.id.task1_row, View.GONE)
        views.setViewVisibility(R.id.task2_row, View.GONE)
        views.setViewVisibility(R.id.task3_row, View.GONE)
    }

    private fun buildProgressRingBitmap(completed: Int, total: Int): Bitmap {
        val size = 102
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val stroke = size * 0.08f
        val inset = stroke / 2f + 4f
        val rect = RectF(inset, inset, size - inset, size - inset)

        val trackPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            this.strokeWidth = stroke
            color = Color.parseColor("#C7E0F0")
        }
        val progressPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            this.strokeWidth = stroke
            color = Color.parseColor("#1A5A96")
            strokeCap = Paint.Cap.ROUND
        }

        canvas.drawArc(rect, 0f, 360f, false, trackPaint)
        if (total > 0 && completed > 0) {
            val sweep = 360f * min(completed.toFloat() / total.toFloat(), 1f)
            canvas.drawArc(rect, -90f, sweep, false, progressPaint)
        }
        return bitmap
    }

    private fun cyclePendingIntent(context: Context, direction: String): PendingIntent {
        val intent = Intent(context, IslandWidgetCycleReceiver::class.java).apply {
            action = IslandWidgetCycleReceiver.ACTION
            putExtra(IslandWidgetCycleReceiver.EXTRA_DIRECTION, direction)
        }
        val requestCode = if (direction == "prev") 101 else 102
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
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

    private fun parsePayload(raw: String?): WidgetPayload = parsePayloadStatic(raw)

    private data class TaskRowIds(
        val rowId: Int,
        val checkBgId: Int,
        val checkMarkId: Int,
        val titleId: Int,
    )

    private data class WidgetPayload(
        val currentIslandId: String,
        val islandName: String,
        val islandStatus: String,
        val todayDate: String = "",
        val completed: Int,
        val total: Int,
        val tasks: List<WidgetTask>,
        val islandIndex: Int = 0,
        val islandTotal: Int = 1,
        val isGrowthMain: Boolean = false,
        val displayLevel: Int = 0,
        val categoryId: String = "",
        val buildingPreviewLevel: Int = 0,
        val buildingThumbPath: String? = null,
    ) {
        val canGoPrev: Boolean get() = islandTotal > 1
        val canGoNext: Boolean get() = islandTotal > 1

        /** App 未打开时跨日：清空昨日任务，强制显示今日空态。 */
        fun forCurrentCalendarDay(now: Date = Date()): WidgetPayload {
            val today = todayDateIso(now)
            // todayDate 为空视为陈旧数据，必须按今日空态展示，避免昨日内容残留。
            if (todayDate == today) return this
            return copy(
                todayDate = today,
                completed = 0,
                total = 0,
                tasks = emptyList(),
            )
        }

        companion object {
            fun empty() = WidgetPayload(
                currentIslandId = "",
                islandName = "星屿",
                islandStatus = "平静",
                todayDate = todayDateIso(),
                completed = 0,
                total = 0,
                tasks = emptyList(),
            )

            fun todayDateIso(date: Date = Date()): String {
                val formatter = SimpleDateFormat("yyyy-MM-dd", Locale.US).apply {
                    timeZone = TimeZone.getDefault()
                }
                return formatter.format(date)
            }
        }
    }

    private data class WidgetTask(
        val id: String,
        val title: String,
        val isDone: Boolean,
    )

    companion object {
        private const val PAYLOAD_KEY = "island_widget_payload"
        private const val CATALOG_KEY = "island_widget_catalog"
        private const val BUILDING_THUMB_KEY = "island_widget_building_thumb"
        private const val MAX_TASKS = 3
        private const val MIDNIGHT_REQUEST_CODE = 91001
        private const val FLUTTER_PREFS = "FlutterSharedPreferences"
        private const val FLUTTER_ISLAND_ID = "flutter.stday_current_island_id"
        private const val FLUTTER_ISLAND_NAME = "flutter.stday_current_island_id_name"
        private const val FLUTTER_ISLAND_GROWTH = "flutter.stday_current_island_id_growth_main"

        /** 在小组件内切换当前岛屿并刷新 UI，不打开 App。 */
        fun cycleIslandInPlace(context: Context, direction: String) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val catalogRaw = widgetData.getString(CATALOG_KEY, null)
            if (catalogRaw.isNullOrBlank()) return

            val current = parsePayloadStatic(widgetData.getString(PAYLOAD_KEY, null))
            if (current.currentIslandId.isEmpty()) return

            val catalog = try {
                JSONArray(catalogRaw)
            } catch (_: Exception) {
                return
            }
            if (catalog.length() <= 1) return

            var index = current.islandIndex
            if (index < 0 || index >= catalog.length()) {
                index = -1
                for (i in 0 until catalog.length()) {
                    val item = catalog.optJSONObject(i) ?: continue
                    if (item.optString("currentIslandId") == current.currentIslandId) {
                        index = i
                        break
                    }
                }
                if (index < 0) index = 0
            }

            val delta = if (direction == "prev") -1 else 1
            val nextIndex = (index + delta + catalog.length()) % catalog.length()
            val nextJson = catalog.optJSONObject(nextIndex) ?: return
            val nextPayloadRaw = nextJson.toString()

            widgetData.edit()
                .putString(PAYLOAD_KEY, nextPayloadRaw)
                .apply()

            syncFlutterCurrentIsland(context, nextJson)

            val provider = IslandWidgetProvider()
            val payload = parsePayloadStatic(nextPayloadRaw).forCurrentCalendarDay()
            val refreshedData = HomeWidgetPlugin.getData(context)
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, IslandWidgetProvider::class.java)
            appWidgetManager.getAppWidgetIds(component).forEach { widgetId ->
                appWidgetManager.updateAppWidget(
                    widgetId,
                    provider.buildRemoteViews(context, payload, refreshedData),
                )
            }
        }

        fun scheduleMidnightRefresh(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val pending = midnightPendingIntent(context)
            val triggerAt = nextMidnightMillis()
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    if (alarmManager.canScheduleExactAlarms()) {
                        alarmManager.setExactAndAllowWhileIdle(
                            AlarmManager.RTC_WAKEUP,
                            triggerAt,
                            pending,
                        )
                    } else {
                        alarmManager.setAndAllowWhileIdle(
                            AlarmManager.RTC_WAKEUP,
                            triggerAt,
                            pending,
                        )
                    }
                } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerAt,
                        pending,
                    )
                } else {
                    alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pending)
                }
            } catch (_: Exception) {
                try {
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerAt,
                        pending,
                    )
                } catch (_: Exception) {
                    // 仍依赖 DATE_CHANGED / updatePeriod。
                }
            }
        }

        fun persistRolloverPayload(context: Context, payload: WidgetPayload) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val json = JSONObject().apply {
                put("currentIslandId", payload.currentIslandId)
                put("islandName", payload.islandName)
                put("islandStatus", payload.islandStatus)
                put("todayDate", payload.todayDate)
                put("completed", payload.completed)
                put("total", payload.total)
                put("islandIndex", payload.islandIndex)
                put("islandTotal", payload.islandTotal)
                put("isGrowthMain", payload.isGrowthMain)
                put("displayLevel", payload.displayLevel)
                put("categoryId", payload.categoryId)
                put("buildingPreviewLevel", payload.buildingPreviewLevel)
                if (payload.buildingThumbPath != null) {
                    put("buildingThumbPath", payload.buildingThumbPath)
                }
                put("todayTasks", JSONArray())
                put("todayMomentCount", 0)
                put(
                    "reviewTitle",
                    if (payload.isGrowthMain) "今日还没有记录" else "${payload.islandName}等待新记录",
                )
                put(
                    "reviewBody",
                    "写下今天的一件小事，小岛会把它放进合适的成长方向，并生成你的日常回顾。",
                )
            }
            widgetData.edit().putString(PAYLOAD_KEY, json.toString()).apply()

            // 同步清空 catalog 里各岛的昨日任务，避免切岛又看到昨日内容。
            val catalogRaw = widgetData.getString(CATALOG_KEY, null) ?: return
            try {
                val catalog = JSONArray(catalogRaw)
                val today = WidgetPayload.todayDateIso()
                for (i in 0 until catalog.length()) {
                    val item = catalog.optJSONObject(i) ?: continue
                    val itemDate = item.optString("todayDate", "")
                    if (itemDate == today) continue
                    item.put("todayDate", today)
                    item.put("completed", 0)
                    item.put("total", 0)
                    item.put("todayTasks", JSONArray())
                    item.put("todayMomentCount", 0)
                    val isMain = item.optBoolean("isGrowthMain", false)
                    val name = item.optString("islandName", "岛屿")
                    item.put(
                        "reviewTitle",
                        if (isMain) "今日还没有记录" else "${name}等待新记录",
                    )
                    item.put(
                        "reviewBody",
                        "写下今天的一件小事，小岛会把它放进合适的成长方向，并生成你的日常回顾。",
                    )
                }
                widgetData.edit().putString(CATALOG_KEY, catalog.toString()).apply()
            } catch (_: Exception) {
                // catalog 损坏时忽略，主 payload 已清空。
            }
        }

        fun cancelMidnightRefresh(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarmManager.cancel(midnightPendingIntent(context))
        }

        private fun midnightPendingIntent(context: Context): PendingIntent {
            val intent = Intent(context, IslandWidgetDayChangeReceiver::class.java).apply {
                action = IslandWidgetDayChangeReceiver.ACTION_MIDNIGHT_REFRESH
            }
            return PendingIntent.getBroadcast(
                context,
                MIDNIGHT_REQUEST_CODE,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        private fun nextMidnightMillis(): Long {
            return Calendar.getInstance().apply {
                add(Calendar.DAY_OF_YEAR, 1)
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 8)
                set(Calendar.MILLISECOND, 0)
            }.timeInMillis
        }

        private fun syncFlutterCurrentIsland(context: Context, json: JSONObject) {
            val id = json.optString("currentIslandId", "")
            if (id.isBlank()) return
            context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
                .edit()
                .putString(FLUTTER_ISLAND_ID, id)
                .putString(
                    FLUTTER_ISLAND_NAME,
                    json.optString("islandName", "岛屿"),
                )
                .putBoolean(
                    FLUTTER_ISLAND_GROWTH,
                    json.optBoolean("isGrowthMain", false),
                )
                .apply()
        }

        private fun parsePayloadStatic(raw: String?): WidgetPayload {
            if (raw.isNullOrBlank()) return WidgetPayload.empty()
            return try {
                parsePayloadJson(JSONObject(raw))
            } catch (_: Exception) {
                WidgetPayload.empty()
            }
        }

        private fun parsePayloadJson(json: JSONObject): WidgetPayload {
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

            return WidgetPayload(
                currentIslandId = islandId,
                islandName = json.optString("islandName", "岛屿"),
                islandStatus = json.optString("islandStatus", "平静"),
                todayDate = json.optString("todayDate", ""),
                completed = json.optInt("completed", 0),
                total = json.optInt("total", 0),
                tasks = tasks,
                islandIndex = json.optInt("islandIndex", 0),
                islandTotal = json.optInt("islandTotal", 1),
                isGrowthMain = json.optBoolean("isGrowthMain", false),
                displayLevel = json.optInt("displayLevel", 0),
                categoryId = json.optString("categoryId", ""),
                buildingPreviewLevel = json.optInt("buildingPreviewLevel", 0),
                buildingThumbPath = json.optString("buildingThumbPath", null),
            )
        }
    }
}

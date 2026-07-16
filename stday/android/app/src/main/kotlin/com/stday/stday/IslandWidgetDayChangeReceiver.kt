package com.stday.stday

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent

/**
 * 系统日期变化（跨日 / 时区 / 手动改日期 / 开机）或午夜闹钟时刷新岛屿小组件，
 * 以便清空昨日任务并显示今日空态。
 */
class IslandWidgetDayChangeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        if (action != Intent.ACTION_DATE_CHANGED &&
            action != Intent.ACTION_TIME_CHANGED &&
            action != Intent.ACTION_TIMEZONE_CHANGED &&
            action != Intent.ACTION_BOOT_COMPLETED &&
            action != Intent.ACTION_LOCKED_BOOT_COMPLETED &&
            action != Intent.ACTION_MY_PACKAGE_REPLACED &&
            action != ACTION_MIDNIGHT_REFRESH
        ) {
            return
        }
        IslandWidgetProvider.scheduleMidnightRefresh(context)
        val manager = AppWidgetManager.getInstance(context)
        val component = ComponentName(context, IslandWidgetProvider::class.java)
        val ids = manager.getAppWidgetIds(component)
        if (ids.isEmpty()) return
        val update = Intent(context, IslandWidgetProvider::class.java).apply {
            this.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        }
        context.sendBroadcast(update)
    }

    companion object {
        const val ACTION_MIDNIGHT_REFRESH = "com.stday.stday.action.WIDGET_MIDNIGHT_REFRESH"
    }
}

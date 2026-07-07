package com.stday.stday

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** ‹ › 在桌面小组件内切换岛屿，不启动 Activity。 */
class IslandWidgetCycleReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION) return
        val direction = intent.getStringExtra(EXTRA_DIRECTION) ?: return
        IslandWidgetProvider.cycleIslandInPlace(context, direction)
    }

    companion object {
        const val ACTION = "com.stday.stday.action.WIDGET_CYCLE_ISLAND"
        const val EXTRA_DIRECTION = "direction"
    }
}

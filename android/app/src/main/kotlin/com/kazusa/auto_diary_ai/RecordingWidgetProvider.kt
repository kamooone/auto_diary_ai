package com.kazusa.auto_diary_ai

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews
import android.widget.Toast

/** ホーム画面に置く、行動履歴の記録のオン・オフを切り替えるボタン */
class RecordingWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, views(context))
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        if (intent.action != ACTION_TOGGLE) return

        val wasEnabled = RecordingController.isEnabled(context)
        val isEnabled = RecordingController.setEnabled(context, !wasEnabled)

        if (!wasEnabled && !isEnabled) {
            Toast.makeText(
                context,
                R.string.recording_widget_start_failed,
                Toast.LENGTH_LONG,
            ).show()
        }
    }

    companion object {
        private const val ACTION_TOGGLE = "com.kazusa.auto_diary_ai.TOGGLE_RECORDING"

        private fun component(context: Context) =
            ComponentName(context, RecordingWidgetProvider::class.java)

        /** 記録の状態が変わったときに、置かれているすべてのウィジェットの表示を更新する */
        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)

            for (id in manager.getAppWidgetIds(component(context))) {
                manager.updateAppWidget(id, views(context))
            }
        }

        /** ホーム画面にウィジェットが置かれているかどうか */
        fun isPinned(context: Context): Boolean {
            return AppWidgetManager.getInstance(context)
                .getAppWidgetIds(component(context))
                .isNotEmpty()
        }

        /** アプリからウィジェットの追加を求められるホームアプリかどうか */
        fun isPinSupported(context: Context): Boolean {
            return Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                AppWidgetManager.getInstance(context).isRequestPinAppWidgetSupported
        }

        /**
         * ウィジェットをホーム画面に追加するよう求める(追加するかどうかはユーザーが確認する)
         * 求められなかった場合はfalse
         */
        fun requestPin(context: Context): Boolean {
            if (!isPinSupported(context)) return false

            return AppWidgetManager.getInstance(context)
                .requestPinAppWidget(component(context), null, null)
        }

        private fun views(context: Context): RemoteViews {
            val enabled = RecordingController.isEnabled(context)

            return RemoteViews(context.packageName, R.layout.recording_widget).apply {
                setTextViewText(
                    R.id.recording_widget_status,
                    context.getString(
                        if (enabled) R.string.recording_widget_on else R.string.recording_widget_off,
                    ),
                )
                setInt(
                    R.id.recording_widget_root,
                    "setBackgroundResource",
                    if (enabled) {
                        R.drawable.recording_widget_background_on
                    } else {
                        R.drawable.recording_widget_background_off
                    },
                )
                setOnClickPendingIntent(R.id.recording_widget_root, clickIntent(context, enabled))
            }
        }

        private fun clickIntent(context: Context, enabled: Boolean): PendingIntent {
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE

            // 位置情報が許可されていないときは、ウィジェットからは許可を求められないためアプリを開く
            if (!enabled && !RecordingController.canStart(context)) {
                return PendingIntent.getActivity(
                    context,
                    0,
                    Intent(context, MainActivity::class.java)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                    flags,
                )
            }

            return PendingIntent.getBroadcast(
                context,
                0,
                Intent(context, RecordingWidgetProvider::class.java).setAction(ACTION_TOGGLE),
                flags,
            )
        }
    }
}

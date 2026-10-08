package com.kazusa.auto_diary_ai.auto_diary_ai

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.util.Log
import androidx.core.content.ContextCompat
import id.flutter.flutter_background_service.BackgroundService
import id.flutter.flutter_background_service.Config
import java.io.File

/**
 * 行動履歴(位置情報と行動認識)の記録のオン・オフ
 *
 * アプリ内のスイッチとホーム画面のウィジェットのどちらからも、ここを通して切り替える。
 * ウィジェットはアプリが動いていないときにも押されるため、状態と切り替えた時刻は
 * ネイティブ側で保存し、Dart側は必要なときに読み出す。
 */
object RecordingController {
    const val CHANNEL = "auto_diary_ai/recording"

    private const val TAG = "RecordingController"
    private const val PREFS = "recording_state"
    private const val KEY_ENABLED = "enabled"
    private const val KEY_WIDGET_PROMPT_SHOWN = "widget_prompt_shown"

    private val lock = Any()

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    // オン・オフを切り替えた時刻の一覧(タイムラインで、オフの間を「記録なし」として扱うために使う)
    private fun historyFile(context: Context): File {
        val directory = File(context.filesDir, "recording").apply { mkdirs() }
        return File(directory, "history.csv")
    }

    /**
     * 記録がオンかどうか
     * 初めて呼ばれたときは、オフの状態から始める
     */
    fun isEnabled(context: Context): Boolean {
        synchronized(lock) {
            val prefs = prefs(context)

            if (!prefs.contains(KEY_ENABLED)) {
                save(context, false)
            }

            return prefs.getBoolean(KEY_ENABLED, false)
        }
    }

    /** 位置情報が許可されていて、記録を開始できる状態かどうか */
    fun canStart(context: Context): Boolean {
        val granted = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED

        // 記録サービスの設定は、アプリを一度起動したときに保存される
        return granted && Config(context).backgroundHandle != 0L
    }

    /**
     * 記録のオン・オフを切り替える
     * 切り替え後の状態を返す(開始できなかった場合はオフのまま)
     */
    fun setEnabled(context: Context, enabled: Boolean): Boolean {
        val appContext = context.applicationContext

        synchronized(lock) {
            val result = if (enabled) start(appContext) else stop(appContext)

            if (result != isEnabled(appContext)) {
                save(appContext, result)
            }

            RecordingWidgetProvider.updateAll(appContext)
            return result
        }
    }

    private fun start(context: Context): Boolean {
        if (!canStart(context)) return false

        try {
            ContextCompat.startForegroundService(
                context,
                Intent(context, BackgroundService::class.java),
            )
        } catch (e: Exception) {
            // アプリが画面に出ていないときは、OSがサービスの開始を認めない場合がある
            Log.w(TAG, "記録を開始できませんでした", e)
            return false
        }

        ActivityRecorder.start(context) {}
        return true
    }

    private fun stop(context: Context): Boolean {
        // 手動で止めたことを記録しておかないと、プラグインがサービスを自動で再開する
        Config(context).setManuallyStopped(true)
        context.stopService(Intent(context, BackgroundService::class.java))

        ActivityRecorder.stop(context)
        return false
    }

    private fun save(context: Context, enabled: Boolean) {
        prefs(context).edit().putBoolean(KEY_ENABLED, enabled).apply()

        historyFile(context).appendText(
            "${if (enabled) "on" else "off"},${System.currentTimeMillis()}\n",
        )
    }

    /** オン・オフを切り替えた時刻の一覧(古い順) */
    fun history(context: Context): List<Map<String, Any>> {
        synchronized(lock) {
            // まだ一度も状態を保存していない場合は、ここで初期状態を保存する
            isEnabled(context)

            return historyFile(context).readLines().mapNotNull { line ->
                val parts = line.split(",")
                val timestamp = parts.getOrNull(1)?.toLongOrNull()

                if (parts.size != 2 || timestamp == null) {
                    null
                } else {
                    mapOf("enabled" to (parts[0] == "on"), "timestamp" to timestamp)
                }
            }
        }
    }

    /**
     * ウィジェットをホーム画面に置くかどうかを、まだ尋ねていないかどうか
     * 尋ねるのは一度だけなので、呼び出すと尋ねたものとして記録する
     */
    fun consumeWidgetPrompt(context: Context): Boolean {
        val prefs = prefs(context)
        if (prefs.getBoolean(KEY_WIDGET_PROMPT_SHOWN, false)) return false

        prefs.edit().putBoolean(KEY_WIDGET_PROMPT_SHOWN, true).apply()
        return true
    }
}

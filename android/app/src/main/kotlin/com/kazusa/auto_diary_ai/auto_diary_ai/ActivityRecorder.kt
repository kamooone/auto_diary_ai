package com.kazusa.auto_diary_ai.auto_diary_ai

import android.Manifest
import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat
import com.google.android.gms.location.ActivityRecognition
import com.google.android.gms.location.ActivityTransition
import com.google.android.gms.location.ActivityTransitionRequest
import com.google.android.gms.location.DetectedActivity
import java.io.File

/**
 * 行動認識(徒歩・自転車・乗り物など)の変化を記録する
 *
 * 行動の変化はアプリが動いていないときにも通知されるため、いったんファイルに溜めておき、
 * Dart側が取り出してIsarへ保存する。
 */
object ActivityRecorder {
    const val CHANNEL = "auto_diary_ai/activity_recorder"

    private const val REQUEST_CODE = 2001
    private val lock = Any()

    private val activityTypes = listOf(
        DetectedActivity.IN_VEHICLE,
        DetectedActivity.ON_BICYCLE,
        DetectedActivity.WALKING,
        DetectedActivity.RUNNING,
        DetectedActivity.STILL,
    )

    private fun directory(context: Context): File {
        return File(context.filesDir, "activity_recorder").apply { mkdirs() }
    }

    // まだDart側に渡していない記録
    private fun pendingFile(context: Context) = File(directory(context), "pending.csv")

    // Dart側に渡したが、Isarへの保存完了がまだ通知されていない記録
    private fun drainingFile(context: Context) = File(directory(context), "draining.csv")

    /** 行動の変化の通知を登録する(身体活動の許可がない場合は何もしない) */
    @SuppressLint("MissingPermission")
    fun start(context: Context, onResult: (Boolean) -> Unit) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.ACTIVITY_RECOGNITION,
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            onResult(false)
            return
        }

        val transitions = activityTypes.map {
            ActivityTransition.Builder()
                .setActivityType(it)
                .setActivityTransition(ActivityTransition.ACTIVITY_TRANSITION_ENTER)
                .build()
        }

        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            flags = flags or PendingIntent.FLAG_MUTABLE
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            Intent(context, ActivityTransitionReceiver::class.java),
            flags,
        )

        ActivityRecognition.getClient(context)
            .requestActivityTransitionUpdates(
                ActivityTransitionRequest(transitions),
                pendingIntent,
            )
            .addOnSuccessListener { onResult(true) }
            .addOnFailureListener { onResult(false) }
    }

    fun append(context: Context, type: String, timestampMillis: Long) {
        synchronized(lock) {
            pendingFile(context).appendText("$type,$timestampMillis\n")
        }
    }

    /**
     * 溜まっている記録をDart側へ渡す
     * Dart側の保存完了(confirmDrain)まではファイルを残し、途中で失敗しても失われないようにする
     */
    fun drain(context: Context): List<Map<String, Any>> {
        synchronized(lock) {
            val pending = pendingFile(context)
            val draining = drainingFile(context)

            if (pending.exists()) {
                draining.appendText(pending.readText())
                pending.delete()
            }

            if (!draining.exists()) return emptyList()

            return draining.readLines().mapNotNull { line ->
                val parts = line.split(",")
                val timestamp = parts.getOrNull(1)?.toLongOrNull()

                if (parts.size != 2 || timestamp == null) {
                    null
                } else {
                    mapOf("type" to parts[0], "timestamp" to timestamp)
                }
            }
        }
    }

    fun confirmDrain(context: Context) {
        synchronized(lock) {
            drainingFile(context).delete()
        }
    }
}

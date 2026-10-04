package com.kazusa.auto_diary_ai.auto_diary_ai

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import com.google.android.gms.location.ActivityTransition
import com.google.android.gms.location.ActivityTransitionResult
import com.google.android.gms.location.DetectedActivity

/** 行動(徒歩・自転車・乗り物など)が変わったときにOSから呼ばれる */
class ActivityTransitionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (!ActivityTransitionResult.hasResult(intent)) return

        val result = ActivityTransitionResult.extractResult(intent) ?: return

        for (event in result.transitionEvents) {
            if (event.transitionType != ActivityTransition.ACTIVITY_TRANSITION_ENTER) continue

            val type = when (event.activityType) {
                DetectedActivity.IN_VEHICLE -> "automotive"
                DetectedActivity.ON_BICYCLE -> "cycling"
                DetectedActivity.WALKING -> "walking"
                DetectedActivity.RUNNING -> "running"
                DetectedActivity.STILL -> "stationary"
                else -> continue
            }

            // イベントの時刻は端末起動からの経過時間で届くため、現在時刻に換算する
            val elapsedMillis =
                (SystemClock.elapsedRealtimeNanos() - event.elapsedRealTimeNanos) / 1_000_000

            ActivityRecorder.append(
                context,
                type,
                System.currentTimeMillis() - elapsedMillis,
            )
        }
    }
}

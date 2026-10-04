package com.kazusa.auto_diary_ai.auto_diary_ai

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 行動認識(徒歩・自転車・乗り物など)の記録をDart側から操作する
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ActivityRecorder.CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> ActivityRecorder.start(applicationContext) { started ->
                    result.success(started)
                }
                "fetchNew" -> result.success(ActivityRecorder.drain(applicationContext))
                "confirm" -> {
                    ActivityRecorder.confirmDrain(applicationContext)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}

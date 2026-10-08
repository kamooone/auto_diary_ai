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

        // 行動履歴の記録のオン・オフと、ホーム画面のウィジェットをDart側から操作する
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            RecordingController.CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isEnabled" -> result.success(RecordingController.isEnabled(applicationContext))
                "setEnabled" -> result.success(
                    RecordingController.setEnabled(
                        applicationContext,
                        call.argument<Boolean>("enabled") ?: false,
                    ),
                )
                "history" -> result.success(RecordingController.history(applicationContext))
                "consumeWidgetPrompt" -> result.success(
                    RecordingController.consumeWidgetPrompt(applicationContext),
                )
                "isWidgetPinSupported" -> result.success(
                    RecordingWidgetProvider.isPinSupported(applicationContext),
                )
                "isWidgetPinned" -> result.success(
                    RecordingWidgetProvider.isPinned(applicationContext),
                )
                "requestPinWidget" -> result.success(
                    RecordingWidgetProvider.requestPin(applicationContext),
                )
                else -> result.notImplemented()
            }
        }
    }

    override fun onResume() {
        super.onResume()

        // 許可の状態が変わると、ウィジェットを押したときの動作が変わるため表示を更新する
        RecordingWidgetProvider.updateAll(applicationContext)
    }
}

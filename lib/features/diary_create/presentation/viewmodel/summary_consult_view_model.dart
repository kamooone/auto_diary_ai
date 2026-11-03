import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/logging/app_log.dart';
import '../../../diary/domain/entities/diary.dart';
import '../../../plan/application/providers/plan_provider.dart';
import '../../../plan/domain/exceptions/usage_limit_exception.dart';
import '../../application/providers/diary_usecase_providers.dart';
import '../../domain/services/consult_prompt.dart';
import '../../domain/usecases/consult_summary_usecase.dart';

class SummaryConsultState {
  const SummaryConsultState({
    this.messages = const [],
    this.isSending = false,
    this.errorMessage,
  });

  final List<ConsultMessage> messages;
  final bool isSending;
  final String? errorMessage;

  SummaryConsultState copyWith({
    List<ConsultMessage>? messages,
    bool? isSending,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SummaryConsultState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// 「日記を1つにする」の書き方を、AIと相談する会話
///
/// 画面を閉じると破棄される(会話も材料メモも残さない)
class SummaryConsultViewModel
    extends AutoDisposeNotifier<SummaryConsultState> {
  late List<Diary> _diaries;

  // 最初の返答で作った、材料の分析メモ。続けての相談では、日記の全文の代わりに送る
  String? _brief;

  // 失敗したときに、もう一度送るための処理
  Future<void> Function()? _retry;

  var _isDisposed = false;

  @override
  SummaryConsultState build() {
    ref.onDispose(() => _isDisposed = true);
    return const SummaryConsultState();
  }

  /// 最初の相談を始める(日記の全文を送る)
  Future<void> start(List<Diary> diaries) {
    _diaries = diaries;
    return _run(_first);
  }

  /// ユーザーの発言を送る
  Future<void> send(String text) {
    final message = text.trim();
    if (message.isEmpty || state.isSending) return Future.value();

    state = state.copyWith(
      messages: [
        ...state.messages,
        ConsultMessage(fromUser: true, text: message),
      ],
    );

    return _run(() => _followUp(message));
  }

  /// 失敗したやり取りを、もう一度送る
  Future<void> retry() {
    final retry = _retry;
    if (retry == null) return Future.value();

    return _run(retry);
  }

  Future<void> _first() async {
    final result = await ref
        .read(consultSummaryUseCaseProvider)
        .start(diaries: _diaries, plan: ref.read(planTypeProvider));

    _brief = result.reply.brief;
    _receive(result);
  }

  Future<void> _followUp(String message) async {
    // 今回の発言は、新しい発言として別に渡すので、会話の履歴には含めない
    final history = state.messages.sublist(0, state.messages.length - 1);

    final result = await ref
        .read(consultSummaryUseCaseProvider)
        .followUp(
          brief: _brief ?? ConsultSummaryUseCase.fallbackBrief(_diaries),
          history: history,
          message: message,
          plan: ref.read(planTypeProvider),
        );

    _receive(result);
  }

  void _receive(ConsultResult result) {
    // この返答で使ったトークン = 返答のあとの今月の累計 − 返答の前の累計
    final before = ref.read(usageProvider)?.usedTokens;

    // 今月の使用量を、画面に反映する
    final usage = result.usage;
    if (usage != null) ref.read(usageProvider.notifier).update(usage);

    if (_isDisposed) return;

    final used = usage != null && before != null && usage.usedTokens >= before
        ? usage.usedTokens - before
        : null;

    state = state.copyWith(
      messages: [
        ...state.messages,
        ConsultMessage(
          fromUser: false,
          text: result.reply.text,
          proposal: result.reply.proposal,
          tokens: used,
        ),
      ],
      isSending: false,
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    if (state.isSending) return;

    _retry = action;
    state = state.copyWith(isSending: true, clearError: true);

    try {
      await action();
    } on UsageLimitExceededException catch (e) {
      final usage = e.usage;
      if (usage != null) ref.read(usageProvider.notifier).update(usage);

      _fail("今月のAIの使用量の上限に達しました");
    } catch (e, stackTrace) {
      AppLog.add('日記', '相談に失敗: $e');
      debugPrint(e.toString());
      debugPrintStack(stackTrace: stackTrace);

      _fail("送信に失敗しました");
    }
  }

  void _fail(String message) {
    if (_isDisposed) return;

    state = state.copyWith(isSending: false, errorMessage: message);
  }
}

final summaryConsultProvider =
    NotifierProvider.autoDispose<SummaryConsultViewModel, SummaryConsultState>(
      SummaryConsultViewModel.new,
    );

import 'dart:async';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../plan/application/providers/plan_provider.dart';
import '../../data/aws_pairing_repository_impl.dart';
import '../../domain/entities/pairing_session.dart';
import '../../domain/repositories/pairing_repository.dart';
import 'device_link_provider.dart';

// ポイントのAPIのURL(.envのPOINTS_API_URL。なければ、下の値)
const _defaultPointsApiUrl =
    'https://137rd6syod.execute-api.ap-northeast-1.amazonaws.com';

// ポイントのWebページのURL(.envのPOINTS_WEB_URL。なければ、下の値)
const _defaultPointsWebUrl = 'https://dq2edjyr3ccb9.cloudfront.net/index.html';

final pointsApiUrlProvider = Provider<String>((ref) {
  return dotenv.maybeGet('POINTS_API_URL', fallback: _defaultPointsApiUrl) ??
      _defaultPointsApiUrl;
});

final pointsWebUrlProvider = Provider<String>((ref) {
  return dotenv.maybeGet('POINTS_WEB_URL', fallback: _defaultPointsWebUrl) ??
      _defaultPointsWebUrl;
});

final pairingRepositoryProvider = Provider<PairingRepository>((ref) {
  return AwsPairingRepositoryImpl(ref.watch(pointsApiUrlProvider));
});

/// 紐づけが済んだかを確認する間隔
final pairingPollIntervalProvider =
    Provider<Duration>((ref) => const Duration(seconds: 3));

/// Webの確認画面に表示する、この端末の名前
final pairingLabelProvider = Provider<String>((ref) {
  if (Platform.isAndroid) return 'Android';
  if (Platform.isIOS) return 'iPhone';
  return 'アプリ';
});

enum PairingPhase {
  /// 何も始めていない
  idle,

  /// コードを発行している
  starting,

  /// コードを表示して、Webでの確定を待っている
  waiting,

  /// コードの期限が切れた
  expired,

  /// コードを発行できなかった
  failed,
}

class PairingState {
  final PairingPhase phase;
  final PairingSession? session;

  const PairingState({this.phase = PairingPhase.idle, this.session});
}

/// 紐づけコードを発行し、Webで確定されるまで確認を続ける
final pairingProvider =
    NotifierProvider.autoDispose<PairingNotifier, PairingState>(
  PairingNotifier.new,
);

class PairingNotifier extends AutoDisposeNotifier<PairingState> {
  Timer? _timer;
  var _isChecking = false;

  // 画面を閉じたあとや、やり直したあとに届いた古い結果を捨てるための番号
  var _generation = 0;

  @override
  PairingState build() {
    ref.onDispose(() {
      _generation++;
      _timer?.cancel();
    });
    return const PairingState();
  }

  /// コードを発行して、紐づけが済むのを待つ
  Future<void> start() async {
    _timer?.cancel();
    final generation = ++_generation;
    state = const PairingState(phase: PairingPhase.starting);

    final PairingSession session;
    try {
      session = await ref
          .read(pairingRepositoryProvider)
          .start(label: ref.read(pairingLabelProvider));
    } catch (_) {
      if (generation == _generation) {
        state = const PairingState(phase: PairingPhase.failed);
      }
      return;
    }

    if (generation != _generation) return;

    state = PairingState(phase: PairingPhase.waiting, session: session);

    _timer = Timer.periodic(
      ref.read(pairingPollIntervalProvider),
      (_) => _check(generation, session),
    );
  }

  /// 発行したコードを取り消す(画面には出さなくなる)
  void cancel() {
    _generation++;
    _timer?.cancel();
    state = const PairingState();
  }

  Future<void> _check(int generation, PairingSession session) async {
    if (_isChecking) return;

    if (session.isExpired) {
      _finish(generation, PairingPhase.expired);
      return;
    }

    _isChecking = true;
    try {
      final result = await ref.read(pairingRepositoryProvider).claim(session);
      if (generation != _generation) return;

      switch (result) {
        case PairingPending():
          break;
        case PairingExpired():
          _finish(generation, PairingPhase.expired);
        case PairingLinked(:final deviceToken):
          _timer?.cancel();
          await ref.read(deviceLinkProvider.notifier).link(deviceToken);
          if (generation != _generation) return;

          state = const PairingState();

          // 紐づけたアカウントのトークン残高を、使用量に反映する
          unawaited(ref.read(usageProvider.notifier).refresh());
      }
    } catch (_) {
      // 通信できなかった。期限まで、確認を続ける
    } finally {
      _isChecking = false;
    }
  }

  void _finish(int generation, PairingPhase phase) {
    if (generation != _generation) return;

    _timer?.cancel();
    state = PairingState(phase: phase, session: state.session);
  }
}

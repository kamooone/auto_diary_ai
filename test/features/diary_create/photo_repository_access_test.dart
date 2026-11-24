import 'dart:async';

import 'package:auto_diary_ai/features/diary_create/data/repositories/photo_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('許可のダイアログが出ている間に、何回問い合わせても、許可は1回だけ求め、全員が同じ答えを受け取る', () async {
    final answer = Completer<bool>();
    var requests = 0;

    final repository = PhotoRepositoryImpl(
      requestAccess: () {
        requests++;
        return answer.future;
      },
    );

    // 写真を選ぶ画面は、一番古い日付と、写真の一覧を、ほぼ同時に読み込む
    final first = repository.hasAccess();
    final second = repository.hasAccess();

    // 利用者が答える前は、どちらも、まだ終わらない(「許可されていない」と、すぐに答えない)
    var secondDone = false;
    unawaited(second.then((_) => secondDone = true));
    await Future<void>.delayed(Duration.zero);
    expect(secondDone, isFalse);

    answer.complete(true);

    expect(await first, isTrue);
    expect(await second, isTrue);
    expect(requests, 1);
  });

  test('答えが出たあとに、また問い合わせたときは、もう一度、許可の状態を確かめる', () async {
    var requests = 0;
    final repository = PhotoRepositoryImpl(
      requestAccess: () async {
        requests++;
        return requests > 1;
      },
    );

    expect(await repository.hasAccess(), isFalse);
    expect(await repository.hasAccess(), isTrue);
    expect(requests, 2);
  });
}

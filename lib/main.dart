import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'app.dart';
import 'core/database/isar_provider.dart';
import 'features/map/data/models/location_log.dart';
import 'features/share/data/models/shared_post_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {

    // Flutterエンジンを初期化する
    // runApp() より前で async 処理やプラグイン（Isar / path_provider など）を使う場合は必ず呼び出す必要がある
    WidgetsFlutterBinding.ensureInitialized();

    // .env読み込み
    await dotenv.load(fileName: ".env");

    // アプリのドキュメントディレクトリを取得
    // DBファイルなど永続データを保存するための安全なアプリ専用領域
    final dir = await getApplicationDocumentsDirectory();

    // Isarデータベースを開く
    // LocationLogSchema は保存するテーブル（コレクション）の定義
    // directory にDBファイルの保存場所を指定
    final isar = await Isar.open(
        [
            LocationLogSchema,
            SharedPostModelSchema,
        ],
        directory: dir.path,
    );

    runApp(
        ProviderScope(

            // isarProvider が返す値を、ここで作成した Isar インスタンスに差し替える
            // これによりアプリ全体で同じ Isar インスタンスを使用できる
            overrides: [
                isarProvider.overrideWithValue(isar),
            ],

            child: const App(),
        ),
    );
}
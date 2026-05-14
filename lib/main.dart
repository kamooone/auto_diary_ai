import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'app.dart';
import 'core/database/isar_provider.dart';
import 'features/map/data/models/location_log.dart';

void main() async {

    WidgetsFlutterBinding.ensureInitialized();

    final dir = await getApplicationDocumentsDirectory();

    final isar = await Isar.open(
        [LocationLogSchema],
        directory: dir.path,
    );

    runApp(
        ProviderScope(
            overrides: [
                isarProvider.overrideWithValue(isar),
            ],
            child: const App(),
        ),
    );
}
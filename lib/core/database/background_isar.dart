import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'isar_schemas.dart';

Future<Isar> openBackgroundIsar() async {
  final dir = await getApplicationDocumentsDirectory();

  return Isar.open(
    isarSchemas,
    directory: dir.path,
  );
}
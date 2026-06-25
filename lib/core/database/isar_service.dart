import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:auto_diary_ai/features/map/data/models/location_log.dart';

class IsarService {

  static Future<Isar> openIsar() async {

    final dir = await getApplicationDocumentsDirectory();

    return await Isar.open(
      [LocationLogSchema],
      directory: dir.path,
      inspector: true,
    );

  }

}
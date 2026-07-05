import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/map_view_model.dart';

final mapProvider =
NotifierProvider<MapViewModel, MapState>(
  MapViewModel.new,
);
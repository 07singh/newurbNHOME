import 'package:flutter/foundation.dart';

class PlotRefreshNotifier {
  static final ValueNotifier<int> instance = ValueNotifier<int>(0);

  /// Call this after any backend change that should force plot data to reload.
  static void notifyRefresh() {
    instance.value++;
  }
}




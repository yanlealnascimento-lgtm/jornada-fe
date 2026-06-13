import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/gamification_providers.dart';
import 'services/crystal_service.dart';

/// Observes app lifecycle events to process midnight crystal checks
/// when the app is resumed from the background.
class AppLifecycleObserver extends WidgetsBindingObserver {
  final WidgetRef _ref;

  AppLifecycleObserver(this._ref);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    }
  }

  Future<void> _onAppResumed() async {
    try {
      final result = await CrystalService.processMidnight();
      if (result.daysProtected > 0 || result.streakBroken) {
        // Invalidate providers so UI reflects the updated state
        invalidateGamificationProviders(_ref);
      }
    } catch (e) {
      debugPrint('[AppLifecycleObserver] Error on resume: $e');
    }
  }
}

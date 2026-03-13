import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VibrationService {
  VibrationService._();

  static final VibrationService instance = VibrationService._();

  static const String _vibrationEnabledKey = 'four_color_game_vibration_enabled';

  bool? _isEnabled;

  Future<bool> isEnabled() async {
    if (_isEnabled != null) {
      return _isEnabled!;
    }

    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_vibrationEnabledKey) ?? true;
    return _isEnabled!;
  }

  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationEnabledKey, enabled);
  }

  Future<void> vibrateBonus() async {
    if (kIsWeb) {
      return;
    }

    final enabled = await isEnabled();
    if (!enabled) {
      return;
    }

    try {
      await HapticFeedback.mediumImpact();
    } catch (e, st) {
      debugPrint('Vibration failed: $e');
      debugPrintStack(stackTrace: st);
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Light tap sound + haptic for interactive controls.
abstract final class VmfsTapFeedback {
  static Future<void> play({bool sound = true, bool haptic = true}) async {
    if (haptic && !kIsWeb) {
      await HapticFeedback.selectionClick();
    }
    if (sound) {
      await SystemSound.play(SystemSoundType.click);
    }
  }

  static Future<void> playPrimary() async {
    if (!kIsWeb) {
      await HapticFeedback.lightImpact();
    }
    await SystemSound.play(SystemSoundType.click);
  }
}

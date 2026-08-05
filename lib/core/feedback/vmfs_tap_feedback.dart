import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Audible tap + haptic for interactive controls.
abstract final class VmfsTapFeedback {
  static final AudioPlayer _tapPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);
  static final AudioPlayer _primaryPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);

  static Future<void> play({bool sound = true, bool haptic = true}) async {
    if (haptic && !kIsWeb) {
      unawaited(HapticFeedback.selectionClick());
    }
    if (sound) {
      unawaited(_playAsset(_tapPlayer, 'sounds/tap_click.wav'));
    }
  }

  static Future<void> playPrimary() async {
    if (!kIsWeb) {
      unawaited(HapticFeedback.lightImpact());
    }
    unawaited(_playAsset(_primaryPlayer, 'sounds/tap_primary.wav'));
  }

  static Future<void> _playAsset(AudioPlayer player, String asset) async {
    try {
      await player.stop();
      await player.play(AssetSource(asset), volume: 0.85);
    } catch (_) {
      await SystemSound.play(SystemSoundType.click);
    }
  }
}

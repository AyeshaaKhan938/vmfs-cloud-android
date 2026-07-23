import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists first-run onboarding flags (separate from auth token).
class OnboardingStorage {
  OnboardingStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Shown once after first login on a fresh app install (e.g. APK from QR page).
  static const firstInstallTutorialKey = 'vmfs_first_install_tutorial_v1';

  @Deprecated('Use firstInstallTutorialKey')
  static const machineListTutorialKey = 'vmfs_machine_list_tutorial_v1';

  @Deprecated('Use firstInstallTutorialKey')
  static const machineDetailTutorialKey = 'vmfs_machine_detail_tutorial_v1';

  @Deprecated('Use firstInstallTutorialKey')
  static const appGuidedTourKey = 'vmfs_app_guided_tour_v1';

  final FlutterSecureStorage _storage;

  Future<bool> hasCompleted(String key) async {
    final value = await _storage.read(key: key);
    return value == '1';
  }

  Future<void> markCompleted(String key) async {
    await _storage.write(key: key, value: '1');
  }

  /// True if the merged first-install tutorial was already completed.
  Future<bool> hasCompletedFirstInstallTutorial() async {
    if (await hasCompleted(firstInstallTutorialKey)) {
      return true;
    }

    // Migrate users who completed the older split tours.
    for (final legacyKey in [
      appGuidedTourKey,
      machineDetailTutorialKey,
      machineListTutorialKey,
    ]) {
      if (await hasCompleted(legacyKey)) {
        await markCompleted(firstInstallTutorialKey);
        return true;
      }
    }

    return false;
  }

  Future<void> markFirstInstallTutorialCompleted() async {
    await markCompleted(firstInstallTutorialKey);
  }

  Future<void> resetFirstInstallTutorial() async {
    await _storage.delete(key: firstInstallTutorialKey);
  }
}

final onboardingStorageProvider = Provider<OnboardingStorage>((ref) => OnboardingStorage());

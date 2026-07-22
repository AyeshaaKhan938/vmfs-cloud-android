import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists first-run onboarding flags (separate from auth token).
class OnboardingStorage {
  OnboardingStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const machineListTutorialKey = 'vmfs_machine_list_tutorial_v1';
  static const machineDetailTutorialKey = 'vmfs_machine_detail_tutorial_v1';
  static const appGuidedTourKey = 'vmfs_app_guided_tour_v1';

  final FlutterSecureStorage _storage;

  Future<bool> hasCompleted(String key) async {
    final value = await _storage.read(key: key);
    return value == '1';
  }

  Future<void> markCompleted(String key) async {
    await _storage.write(key: key, value: '1');
  }

  Future<void> resetMachineTutorials() async {
    await _storage.delete(key: machineListTutorialKey);
    await _storage.delete(key: machineDetailTutorialKey);
  }

  Future<void> resetAppGuidedTour() async {
    await _storage.delete(key: appGuidedTourKey);
  }

  Future<void> resetAllTutorials() async {
    await resetMachineTutorials();
    await resetAppGuidedTour();
  }
}

final onboardingStorageProvider = Provider<OnboardingStorage>((ref) => OnboardingStorage());

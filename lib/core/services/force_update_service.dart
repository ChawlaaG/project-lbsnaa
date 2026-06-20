import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service that checks if the current app version meets the minimum
/// required version stored in Firestore. If not, it shows a blocking
/// dialog that directs users to the Play Store.
class ForceUpdateService {
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.cadre.upsc';

  /// Checks Firestore `app_config/settings` for `minRequiredVersion`.
  /// Returns `true` if the current version is outdated.
  static Future<bool> isUpdateRequired() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('settings')
          .get();

      if (!doc.exists || doc.data() == null) return false;

      final minVersion = doc.data()!['minRequiredVersion'] as String?;
      if (minVersion == null || minVersion.isEmpty) return false;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // e.g. "1.0.3"

      return _isOlderThan(currentVersion, minVersion);
    } catch (e) {
      // If check fails (no internet, missing doc, etc.), don't block the user
      debugPrint('ForceUpdateService: check failed — $e');
      return false;
    }
  }

  /// Compares two semantic version strings (e.g. "1.0.3" vs "1.1.0").
  /// Returns true if [current] is strictly older than [minimum].
  static bool _isOlderThan(String current, String minimum) {
    final currentParts = current.split('.').map(int.parse).toList();
    final minimumParts = minimum.split('.').map(int.parse).toList();

    // Pad to 3 parts
    while (currentParts.length < 3) {
      currentParts.add(0);
    }
    while (minimumParts.length < 3) {
      minimumParts.add(0);
    }

    for (int i = 0; i < 3; i++) {
      if (currentParts[i] < minimumParts[i]) return true;
      if (currentParts[i] > minimumParts[i]) return false;
    }
    return false; // Equal versions — not outdated
  }

  /// Shows a non-dismissible dialog forcing user to update.
  static Future<void> showUpdateDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Row(
            children: [
              Icon(Icons.system_update, color: Colors.amber, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Update Required',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'A new version of CADRE is available. Please update to continue using the app.',
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: _openPlayStore,
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Update Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _openPlayStore() async {
    final uri = Uri.parse(_playStoreUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

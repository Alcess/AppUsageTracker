import 'family_link_service.dart';
import 'fcm_service.dart';

class CommandService {
  /// Send a device lock command to child device
  static Future<bool> lockDevice() async {
    final childFCMToken = await FamilyLinkService.getChildFCMToken();

    if (childFCMToken == null) {
      return false;
    }

    return await FCMService.sendCommand(
      childToken: childFCMToken,
      action: 'lock_device',
      appPackage: null,
    );
  }

  /// Send a device unlock command to child device
  static Future<bool> unlockDevice() async {
    final childFCMToken = await FamilyLinkService.getChildFCMToken();

    if (childFCMToken == null) {
      return false;
    }

    return await FCMService.sendCommand(
      childToken: childFCMToken,
      action: 'unlock_device',
      appPackage: null,
    );
  }

  /// Send a lock command to child device for specific app (deprecated)
  static Future<bool> lockApp(String appPackage) async {
    final childFCMToken = await FamilyLinkService.getChildFCMToken();

    if (childFCMToken == null) {
      return false;
    }

    return await FCMService.sendCommand(
      childToken: childFCMToken,
      action: 'lock',
      appPackage: appPackage,
    );
  }

  /// Send an unlock command to child device for specific app
  static Future<bool> unlockApp(String appPackage) async {
    final childFCMToken = await FamilyLinkService.getChildFCMToken();

    if (childFCMToken == null) {
      return false;
    }

    return await FCMService.sendCommand(
      childToken: childFCMToken,
      action: 'unlock',
      appPackage: appPackage,
    );
  }

  /// Send a time limit command to child device
  static Future<bool> setTimeLimit(String appPackage, int minutes) async {
    final childFCMToken = await FamilyLinkService.getChildFCMToken();

    if (childFCMToken == null) {
      return false;
    }

    return await FCMService.sendCommand(
      childToken: childFCMToken,
      action: 'time_limit',
      appPackage: appPackage,
    );
  }

  /// Send an emergency unlock command to clear all overlays
  static Future<bool> emergencyUnlockAll() async {
    final childFCMToken = await FamilyLinkService.getChildFCMToken();

    if (childFCMToken == null) {
      return false;
    }

    return await FCMService.sendCommand(
      childToken: childFCMToken,
      action: 'emergency_unlock',
      appPackage: null,
    );
  }

  /// Check if parent is linked to a child device
  static Future<bool> canSendCommands() async {
    final isLinked = await FamilyLinkService.isLinked();
    final childToken = await FamilyLinkService.getChildFCMToken();
    return isLinked && childToken != null;
  }
}

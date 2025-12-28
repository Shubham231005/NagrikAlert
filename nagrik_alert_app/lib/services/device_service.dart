import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static String? _cachedDeviceId;

  /// Get unique device identifier for anti-spam fingerprinting
  static Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    try {
      if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        _cachedDeviceId = '${webInfo.browserName}-${webInfo.hardwareConcurrency}-${webInfo.platform}';
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        _cachedDeviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _cachedDeviceId = iosInfo.identifierForVendor ?? 'unknown_ios';
      } else {
        _cachedDeviceId = 'unknown_device_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      _cachedDeviceId = 'fallback_${DateTime.now().millisecondsSinceEpoch}';
    }

    return _cachedDeviceId!;
  }

  /// Get device info for debugging
  static Future<Map<String, String>> getDeviceInfo() async {
    final info = <String, String>{};

    try {
      if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        info['platform'] = 'Web';
        info['browser'] = webInfo.browserName.name;
        info['userAgent'] = webInfo.userAgent ?? 'unknown';
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        info['platform'] = 'Android';
        info['model'] = androidInfo.model;
        info['manufacturer'] = androidInfo.manufacturer;
        info['sdk'] = androidInfo.version.sdkInt.toString();
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        info['platform'] = 'iOS';
        info['model'] = iosInfo.model;
        info['version'] = iosInfo.systemVersion;
      }
    } catch (e) {
      info['error'] = e.toString();
    }

    return info;
  }
}

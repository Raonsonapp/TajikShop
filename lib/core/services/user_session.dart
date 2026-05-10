// lib/core/services/user_session.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  UserSession._();

  static String? userId;
  static String? email;

  static const _keyAvatar   = 'cached_avatar_url';
  static const _keyUserId   = 'cached_user_id';
  static const _keyEmail    = 'cached_email';
  static const _keyFullName = 'cached_full_name';
  static const _keyRole     = 'cached_role';

  // ValueNotifier — avatar UI автоматӣ update мешавад
  static final ValueNotifier<String?> avatarNotifier = ValueNotifier<String?>(null);
  static final ValueNotifier<String?> fullNameNotifier = ValueNotifier<String?>(null);
  static final ValueNotifier<String> roleNotifier = ValueNotifier<String>('buyer');

  static String? get avatar => avatarNotifier.value;
  static String? get fullName => fullNameNotifier.value;
  static String get role => roleNotifier.value;

  static set avatar(String? v) {
    avatarNotifier.value = v;
    _persist(_keyAvatar, v);
  }

  static set fullName(String? v) {
    fullNameNotifier.value = v;
    _persist(_keyFullName, v);
  }

  static set role(String v) {
    roleNotifier.value = v;
    _persist(_keyRole, v);
  }

  /// Бори аввал — аз SharedPreferences хондан
  static Future<void> loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedAvatar = prefs.getString(_keyAvatar);
      if (cachedAvatar != null && cachedAvatar.isNotEmpty) {
        avatarNotifier.value = cachedAvatar;
      }
      final cachedId = prefs.getString(_keyUserId);
      if (cachedId != null && cachedId.isNotEmpty) userId = cachedId;

      final cachedEmail = prefs.getString(_keyEmail);
      if (cachedEmail != null) email = cachedEmail;

      final cachedName = prefs.getString(_keyFullName);
      if (cachedName != null) fullNameNotifier.value = cachedName;

      final cachedRole = prefs.getString(_keyRole);
      if (cachedRole != null) roleNotifier.value = cachedRole;
    } catch (_) {}
  }

  /// Маълумоти корбарро нав кун ва захира кун
  static Future<void> saveAll({
    required String id,
    required String userEmail,
    required String name,
    required String avatarUrl,
    required String userRole,
  }) async {
    userId = id;
    email  = userEmail;
    avatarNotifier.value  = avatarUrl.isNotEmpty ? avatarUrl : null;
    fullNameNotifier.value = name;
    roleNotifier.value    = userRole;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserId,   id);
      await prefs.setString(_keyEmail,    userEmail);
      await prefs.setString(_keyFullName, name);
      await prefs.setString(_keyRole,     userRole);
      if (avatarUrl.isNotEmpty) await prefs.setString(_keyAvatar, avatarUrl);
    } catch (_) {}
  }

  /// Вақти logout — тоза кун
  static Future<void> clear() async {
    userId = null;
    email  = null;
    avatarNotifier.value  = null;
    fullNameNotifier.value = null;
    roleNotifier.value    = 'buyer';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAvatar);
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyEmail);
      await prefs.remove(_keyFullName);
      await prefs.remove(_keyRole);
    } catch (_) {}
  }

  static Future<void> _persist(String key, String? value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value != null && value.isNotEmpty) {
        await prefs.setString(key, value);
      } else {
        await prefs.remove(key);
      }
    } catch (_) {}
  }
}

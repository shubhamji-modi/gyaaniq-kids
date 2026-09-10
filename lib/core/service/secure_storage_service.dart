import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Crash-safe wrapper around [FlutterSecureStorage].
///
/// Android ke keystore me rakhi hui key kabhi-kabhi app ke data se out of sync
/// ho jaati hai — Android Auto Backup / device-to-device transfer purani
/// encrypted prefs restore kar deta hai lekin keystore key restore nahi hoti,
/// ya OEM keystore reset kar deta hai. Us case me har read
/// `BadPaddingException: BAD_DECRYPT` throw karta hai aur app splash par hi
/// crash ho jaati hai.
///
/// Isliye yahan do layers hain:
///  * `resetOnError: true` — plugin khud corrupt data clear kar deta hai
///    throw karne ke bajaye.
///  * har call try/catch me — agar phir bhi kuch aaya to storage clear karke
///    null return hota hai, yaani user sirf logged out hota hai, crash nahi.
class SecureStorageService {
  const SecureStorageService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } on PlatformException catch (error) {
      debugPrint('SecureStorage read failed for "$key": $error');
      await deleteAll();
      return null;
    } catch (error) {
      debugPrint('SecureStorage read failed for "$key": $error');
      return null;
    }
  }

  static Future<void> write(String key, String? value) async {
    try {
      await _storage.write(key: key, value: value);
    } on PlatformException catch (error) {
      debugPrint('SecureStorage write failed for "$key": $error');
      // Corrupt store ko clear karke ek baar dobara koshish karo.
      await deleteAll();
      try {
        await _storage.write(key: key, value: value);
      } catch (retryError) {
        debugPrint('SecureStorage write retry failed: $retryError');
      }
    } catch (error) {
      debugPrint('SecureStorage write failed for "$key": $error');
    }
  }

  static Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (error) {
      debugPrint('SecureStorage delete failed for "$key": $error');
    }
  }

  static Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (error) {
      debugPrint('SecureStorage deleteAll failed: $error');
    }
  }
}

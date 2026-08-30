import 'dart:io';

/// Minimal connectivity check that doesn't require an extra plugin
/// dependency. Attempts a fast DNS lookup; if it fails we treat the device
/// as offline. This is a best-effort check used to short-circuit AI calls
/// with a friendly "no internet" message rather than waiting for a timeout.
class NetworkUtils {
  NetworkUtils._();

  static Future<bool> hasConnection() async {
    try {
      final result = await InternetAddress.lookup('api.groq.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } catch (_) {
      return false;
    }
  }
}

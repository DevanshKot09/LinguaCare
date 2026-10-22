// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:convert';

void main() {
  try {
    final file = File('android/app/google-services.json');
    if (!file.existsSync()) {
      print('FAIL');
      exit(1);
    }
    final content = file.readAsStringSync();
    final json = jsonDecode(content) as Map<String, dynamic>;

    bool pkgMatch = false;
    final clients = json['client'] as List<dynamic>?;
    if (clients != null) {
      for (final c in clients) {
        final clientInfo = c['client_info'] as Map<String, dynamic>?;
        if (clientInfo != null) {
          final androidClientInfo = clientInfo['android_client_info'] as Map<String, dynamic>?;
          if (androidClientInfo != null) {
            final pkgName = androidClientInfo['package_name'];
            if (pkgName == 'com.linguacare.app.linguacare') {
              pkgMatch = true;
            }
          }
        }
      }
    }

    // Also check client list or top-level oauth_client or client oauth
    bool hasWebClient = false;
    if (clients != null) {
      for (final c in clients) {
        final oauthClients = c['oauth_client'] as List<dynamic>?;
        if (oauthClients != null) {
          for (final o in oauthClients) {
            if (o['client_type'] == 3) {
              hasWebClient = true;
            }
          }
        }
      }
    }
    final topOauth = json['oauth_client'] as List<dynamic>?;
    if (topOauth != null) {
      for (final o in topOauth) {
        if (o['client_type'] == 3) {
          hasWebClient = true;
        }
      }
    }

    if (pkgMatch && hasWebClient) {
      print('PASS');
    } else {
      print('FAIL');
      exit(1);
    }
  } catch (_) {
    print('FAIL');
    exit(1);
  }
}

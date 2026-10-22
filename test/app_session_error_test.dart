import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linguacare/app/router/app_session.dart';

void main() {
  test('AppSession initializes with safe default when SharedPreferences is unavailable', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final sessionNotifier = container.read(appSessionProvider);
    expect(sessionNotifier.value.isFirstLaunch, isTrue);
  });
}

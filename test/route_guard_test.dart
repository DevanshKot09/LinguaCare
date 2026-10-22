import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:linguacare/app/router/app_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('AppSession initial state and updates', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await Future.delayed(const Duration(milliseconds: 100));

    container.read(appSessionProvider).debugSetState(
          isSignedIn: true,
          hasProfile: true,
          role: UserRole.parent,
          onboardingDone: true,
        );

    final updatedState = container.read(appSessionStateProvider);
    expect(updatedState.isSignedIn, true);
    expect(updatedState.role, UserRole.parent);
  });
}

import '../../app/router/app_session.dart';
import 'profile.dart';

abstract class ProfileRepository {
  Future<Profile?> getProfile(String uid);
  Future<void> completeProfile({
    required UserRole role,
    required String fullName,
    required String country,
    required String language,
    Map<String, dynamic> roleDetails = const {},
    Map<String, dynamic>? initialChild,
    List<Map<String, dynamic>> consents = const [],
  });
  Future<String> addChild({
    required String nickname,
    required DateTime dob,
    List<String> homeLanguages = const [],
    List<String> interests = const [],
    List<String> concerns = const [],
    List<Map<String, dynamic>> consents = const [],
  });
  Future<void> deleteChild(String childId);
  Future<void> deleteAccount();
}

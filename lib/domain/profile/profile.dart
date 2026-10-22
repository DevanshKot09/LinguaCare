import '../../app/router/app_session.dart';

enum AgeBand { band5_11, band11_18 }

class Child {
  final String id;
  final String parentUid;
  final String nickname;
  final DateTime dob;
  final AgeBand band;
  final List<String> homeLanguages;
  final List<String> interests;
  final List<String> concerns;

  const Child({
    required this.id,
    required this.parentUid,
    required this.nickname,
    required this.dob,
    required this.band,
    required this.homeLanguages,
    required this.interests,
    required this.concerns,
  });

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['id'] as String,
      parentUid: json['parent_uid'] as String,
      nickname: json['nickname'] as String,
      dob: DateTime.parse(json['dob'] as String),
      band: ((json['band'] as String?) == '11_18') ? AgeBand.band11_18 : AgeBand.band5_11,
      homeLanguages: List<String>.from(json['home_languages'] ?? []),
      interests: List<String>.from(json['interests'] ?? []),
      concerns: List<String>.from(json['concerns'] ?? []),
    );
  }
}

class Profile {
  final String uid;
  final UserRole role;
  final String fullName;
  final String email;
  final bool emailVerified;
  final String? country;
  final String language;
  final bool verified;
  final Map<String, dynamic>? roleDetails;
  final List<Child> children;

  const Profile({
    required this.uid,
    required this.role,
    required this.fullName,
    required this.email,
    required this.emailVerified,
    this.country,
    required this.language,
    required this.verified,
    this.roleDetails,
    required this.children,
  });
}

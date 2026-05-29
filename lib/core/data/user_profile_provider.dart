import 'package:flutter/material.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String mobile;
  final String instructionMedium;
  final String educationBoard;
  final String userClass;
  final String profilePic;

  UserProfile({
    this.id = '',
    required this.name,
    this.email = '',
    this.mobile = '',
    required this.instructionMedium,
    required this.educationBoard,
    required this.userClass,
    this.profilePic = '',
  });

  factory UserProfile.fromApi(Map<String, dynamic> json) {
    return UserProfile(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Student',
      email: json['email']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? json['phone']?.toString() ?? '',
      instructionMedium: json['instructionMedium']?.toString() ?? 'English',
      educationBoard: json['educationalBoard']?.toString() ?? 'CBSE',
      userClass: json['classLevel']?.toString() ?? '-',
      profilePic: json['profilePic']?.toString() ?? '',
    );
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? mobile,
    String? instructionMedium,
    String? educationBoard,
    String? userClass,
    String? profilePic,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      instructionMedium: instructionMedium ?? this.instructionMedium,
      educationBoard: educationBoard ?? this.educationBoard,
      userClass: userClass ?? this.userClass,
      profilePic: profilePic ?? this.profilePic,
    );
  }

  Map<String, dynamic> toProfilePayload() {
    return {
      'name': name,
      'instructionMedium': instructionMedium,
      'classLevel': userClass,
      'educationalBoard': educationBoard,
      'profilePic': profilePic,
    };
  }
}

class UserProfileProvider with ChangeNotifier {
  UserProfile? _profile;

  UserProfile? get profile => _profile;

  void setProfile(UserProfile profile) {
    _profile = profile;
    notifyListeners();
  }

  void clearProfile() {
    _profile = null;
    notifyListeners();
  }
}

import 'package:flutter/material.dart';

class UserProfile {
  final String name;
  final String instructionMedium;
  final String educationBoard;
  final String userClass;

  UserProfile({
    required this.name,
    required this.instructionMedium,
    required this.educationBoard,
    required this.userClass,
  });
}

class UserProfileProvider with ChangeNotifier {
  UserProfile? _profile;

  UserProfile? get profile => _profile;

  void setProfile(UserProfile profile) {
    _profile = profile;
    notifyListeners();
  }
}

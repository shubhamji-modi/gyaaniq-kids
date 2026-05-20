import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  @JsonKey(name: '_id')
  final String id;
  final String name;
  final String email;
  @JsonKey(name: 'profilePicture')
  final String? profilePicture;
  final String role;
  final String status;
  @JsonKey(name: 'registrationDate')
  final DateTime? registrationDate;
  @JsonKey(name: 'lastLoginDate')
  final DateTime? lastLoginDate;
  @JsonKey(name: 'isDeleted')
  final bool isDeleted;
  @JsonKey(name: 'updatedAt')
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.profilePicture,
    required this.role,
    required this.status,
    this.registrationDate,
    this.lastLoginDate,
    required this.isDeleted,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}

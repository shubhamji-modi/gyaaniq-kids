// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['_id'] as String,
  name: json['name'] as String,
  email: json['email'] as String,
  profilePicture: json['profilePicture'] as String?,
  role: json['role'] as String,
  status: json['status'] as String,
  registrationDate:
  json['registrationDate'] == null
      ? null
      : DateTime.parse(json['registrationDate'] as String),
  lastLoginDate:
  json['lastLoginDate'] == null
      ? null
      : DateTime.parse(json['lastLoginDate'] as String),
  isDeleted: json['isDeleted'] as bool,
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  '_id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'profilePicture': instance.profilePicture,
  'role': instance.role,
  'status': instance.status,
  'registrationDate': instance.registrationDate?.toIso8601String(),
  'lastLoginDate': instance.lastLoginDate?.toIso8601String(),
  'isDeleted': instance.isDeleted,
  'updatedAt': instance.updatedAt.toIso8601String(),
};

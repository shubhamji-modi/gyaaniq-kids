import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'login_response.g.dart';

@JsonSerializable()
class LoginResponse {
  final String status;
  final String message;
  final String token;
  final User user;

  LoginResponse({
    required this.status,
    required this.message,
    required this.token,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
}

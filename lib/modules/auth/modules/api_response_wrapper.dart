import 'package:json_annotation/json_annotation.dart';
part 'api_response_wrapper.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class ApiResponseWrapper<T> {
  final String status;
  final String message;
  final T? data;

  ApiResponseWrapper({
    required this.status,
    required this.message,
    this.data,
  });

  factory ApiResponseWrapper.fromJson(
      Map<String, dynamic> json,
      T Function(Object? json) fromJsonT,
      ) => _$ApiResponseWrapperFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object Function(T value) toJsonT) =>
      _$ApiResponseWrapperToJson(this, toJsonT);

  bool get isSuccess => status == 'success';
}
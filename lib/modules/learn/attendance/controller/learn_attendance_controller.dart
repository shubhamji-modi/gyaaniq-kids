import 'package:edupath_learning/core/service/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LearnAttendanceController extends GetxController {
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final Rx<DateTime> visibleMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  ).obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxList<AttendanceDayModel> days = <AttendanceDayModel>[].obs;
  final Rx<AttendanceSummaryModel> summary = AttendanceSummaryModel.empty().obs;

  @override
  void onInit() {
    super.onInit();
    fetchAttendance();
  }

  Future<void> fetchAttendance() async {
    isLoading.value = true;
    errorMessage.value = '';

    final month = _formatMonth(visibleMonth.value);
    final summaryFrom = '$month-01';
    final summaryTo =
        '$month-${DateUtils.getDaysInMonth(visibleMonth.value.year, visibleMonth.value.month).toString().padLeft(2, '0')}';

    final responses = await Future.wait([
      LearnAttendanceRepository.fetchMonthlyAttendance(month),
      LearnAttendanceRepository.fetchAttendanceSummary(
        from: summaryFrom,
        to: summaryTo,
      ),
    ]);

    final monthResponse = responses[0] as ApiResponse<List<AttendanceDayModel>>;
    final summaryResponse = responses[1] as ApiResponse<AttendanceSummaryModel>;

    isLoading.value = false;

    if (!monthResponse.success) {
      days.clear();
      summary.value = AttendanceSummaryModel.empty();
      errorMessage.value = monthResponse.message;
      return;
    }

    days.assignAll(monthResponse.data ?? const <AttendanceDayModel>[]);
    if (summaryResponse.success) {
      summary.value = summaryResponse.data ?? AttendanceSummaryModel.empty();
    } else {
      summary.value = AttendanceSummaryModel.fromDays(days);
    }
  }

  Future<void> changeMonth(int offset) async {
    final nextMonth = DateTime(
      visibleMonth.value.year,
      visibleMonth.value.month + offset,
    );
    visibleMonth.value = nextMonth;
    final daysInMonth = DateUtils.getDaysInMonth(
      nextMonth.year,
      nextMonth.month,
    );
    final safeDay = selectedDate.value.day.clamp(1, daysInMonth);
    selectedDate.value = DateTime(nextMonth.year, nextMonth.month, safeDay);
    await fetchAttendance();
  }

  void selectDate(DateTime date) {
    selectedDate.value = date;
  }

  AttendanceDayModel? get selectedAttendanceDay {
    return days.firstWhereOrNull((day) {
      return DateUtils.isSameDay(day.date, selectedDate.value);
    });
  }

  static String _formatMonth(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';
  }
}

class LearnAttendanceRepository {
  static Future<ApiResponse<List<AttendanceDayModel>>> fetchMonthlyAttendance(
    String month,
  ) async {
    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.USER_ATTENDANCE,
      queryParameters: {'month': month},
      showLoader: false,
      fromJson: (json) => json,
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      return ApiResponse<List<AttendanceDayModel>>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    final body = response.data as Map<String, dynamic>;
    final data = body['data'];
    final rawDays = data is Map<String, dynamic> ? data['days'] : null;
    final items = rawDays is List
        ? rawDays
              .whereType<Map<String, dynamic>>()
              .map(AttendanceDayModel.fromApi)
              .toList()
        : <AttendanceDayModel>[];

    return ApiResponse<List<AttendanceDayModel>>(
      success: true,
      data: items,
      message: response.message,
      statusCode: response.statusCode,
    );
  }

  static Future<ApiResponse<AttendanceSummaryModel>> fetchAttendanceSummary({
    required String from,
    required String to,
  }) async {
    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.USER_ATTENDANCE_SUMMARY,
      queryParameters: {'from': from, 'to': to},
      showLoader: false,
      fromJson: (json) => json,
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      return ApiResponse<AttendanceSummaryModel>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    final body = response.data as Map<String, dynamic>;
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      return ApiResponse<AttendanceSummaryModel>(
        success: false,
        message: 'Attendance summary not found.',
        statusCode: response.statusCode,
      );
    }

    return ApiResponse<AttendanceSummaryModel>(
      success: true,
      data: AttendanceSummaryModel.fromApi(data),
      message: response.message,
      statusCode: response.statusCode,
    );
  }
}

enum AttendanceStatus {
  present,
  absent,
  notAttend,
  holiday;

  static AttendanceStatus fromApi(String? value) {
    switch (value) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'holiday':
        return AttendanceStatus.holiday;
      case 'not_attend':
      default:
        return AttendanceStatus.notAttend;
    }
  }

  String get label {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.notAttend:
        return 'Not Attend';
      case AttendanceStatus.holiday:
        return 'Holiday';
    }
  }
}

class AttendanceDayModel {
  const AttendanceDayModel({
    required this.date,
    required this.status,
    this.note = '',
    this.markedAt,
  });

  final DateTime date;
  final AttendanceStatus status;
  final String note;
  final DateTime? markedAt;

  factory AttendanceDayModel.fromApi(Map<String, dynamic> json) {
    return AttendanceDayModel(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      status: AttendanceStatus.fromApi(json['status']?.toString()),
      note: json['note']?.toString() ?? '',
      markedAt: DateTime.tryParse(json['markedAt']?.toString() ?? ''),
    );
  }
}

class AttendanceSummaryModel {
  const AttendanceSummaryModel({
    required this.present,
    required this.absent,
    required this.notAttend,
    required this.holidays,
    required this.total,
    required this.percentage,
  });

  final int present;
  final int absent;
  final int notAttend;
  final int holidays;
  final int total;
  final double percentage;

  factory AttendanceSummaryModel.empty() {
    return const AttendanceSummaryModel(
      present: 0,
      absent: 0,
      notAttend: 0,
      holidays: 0,
      total: 0,
      percentage: 0,
    );
  }

  factory AttendanceSummaryModel.fromApi(Map<String, dynamic> json) {
    return AttendanceSummaryModel(
      present: _readInt(json['present']),
      absent: _readInt(json['absent']),
      notAttend: _readInt(json['notAttend']),
      holidays: _readInt(json['holidays']),
      total: _readInt(json['total']),
      percentage: _readDouble(json['percentage']),
    );
  }

  factory AttendanceSummaryModel.fromDays(List<AttendanceDayModel> days) {
    final present = days
        .where((day) => day.status == AttendanceStatus.present)
        .length;
    final absent = days
        .where((day) => day.status == AttendanceStatus.absent)
        .length;
    final notAttend = days
        .where((day) => day.status == AttendanceStatus.notAttend)
        .length;
    final holidays = days
        .where((day) => day.status == AttendanceStatus.holiday)
        .length;
    final total = present + absent + notAttend;
    final percentage = total == 0 ? 0.0 : (present / total) * 100;
    return AttendanceSummaryModel(
      present: present,
      absent: absent,
      notAttend: notAttend,
      holidays: holidays,
      total: total,
      percentage: double.parse(percentage.toStringAsFixed(2)),
    );
  }
}

int _readInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _readDouble(dynamic value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

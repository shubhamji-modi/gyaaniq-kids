import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/service/api_service.dart';

class LearnHomeworkController extends GetxController {
  final Rx<LearnHomeworkTab> selectedTab = LearnHomeworkTab.pending.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<LearnHomeworkModel> assignments = <LearnHomeworkModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchHomework();
  }

  void changeTab(LearnHomeworkTab tab) {
    if (selectedTab.value == tab) {
      return;
    }
    selectedTab.value = tab;
    fetchHomework();
  }

  Future<void> fetchHomework() async {
    isLoading.value = true;
    errorMessage.value = '';

    final response = await LearnHomeworkRepository.fetchHomeworkByTab(
      selectedTab.value,
    );

    isLoading.value = false;

    if (!response.success) {
      assignments.clear();
      errorMessage.value = response.message;
      return;
    }

    assignments.assignAll(response.data ?? const <LearnHomeworkModel>[]);
  }
}

class LearnHomeworkRepository {
  static Future<ApiResponse<List<LearnHomeworkModel>>> fetchHomeworkByTab(
    LearnHomeworkTab tab,
  ) async {
    final statuses = tab == LearnHomeworkTab.pending
        ? const ['pending', 'overdue']
        : const ['submitted', 'graded'];
    final allItems = <LearnHomeworkModel>[];

    for (final status in statuses) {
      final response = await fetchHomework(status: status);
      if (!response.success) {
        return response;
      }
      allItems.addAll(response.data ?? const <LearnHomeworkModel>[]);
    }

    return ApiResponse<List<LearnHomeworkModel>>(
      success: true,
      data: allItems,
      message: 'Success',
      statusCode: 200,
    );
  }

  static Future<ApiResponse<List<LearnHomeworkModel>>> fetchHomework({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.HOMEWORK,
      showLoader: false,
      queryParameters: {
        if (status != null && status.trim().isNotEmpty) 'status': status,
        'page': page,
        'limit': limit,
      },
      fromJson: (json) => json,
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      return ApiResponse<List<LearnHomeworkModel>>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    final body = response.data as Map<String, dynamic>;
    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    final itemsJson = data['homework'] as List<dynamic>? ?? const [];
    final items = itemsJson
        .whereType<Map<String, dynamic>>()
        .map(LearnHomeworkModel.fromApi)
        .toList();

    return ApiResponse<List<LearnHomeworkModel>>(
      success: true,
      data: items,
      message: body['message']?.toString() ?? 'Success',
      statusCode: response.statusCode,
    );
  }

  static Future<ApiResponse<LearnHomeworkModel>> fetchHomeworkDetail(
    String id,
  ) async {
    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.HOMEWORK_DETAIL.replaceFirst(':id', id),
      showLoader: false,
      fromJson: (json) => json,
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      return ApiResponse<LearnHomeworkModel>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    final body = response.data as Map<String, dynamic>;
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      return ApiResponse<LearnHomeworkModel>(
        success: false,
        message: 'Homework detail not found.',
        statusCode: response.statusCode,
      );
    }

    return ApiResponse<LearnHomeworkModel>(
      success: true,
      data: LearnHomeworkModel.fromApi(data),
      message: body['message']?.toString() ?? 'Success',
      statusCode: response.statusCode,
    );
  }

  static Future<ApiResponse<HomeworkAttachment>> uploadAttachment(
    String filePath,
  ) async {
    final response = await ApiService.instance.uploadFile<dynamic>(
      endpoint: ApiService.HOMEWORK_UPLOAD_ATTACHMENT,
      filePath: filePath,
      showLoader: false,
      fromJson: (json) => json,
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      return ApiResponse<HomeworkAttachment>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    final body = response.data as Map<String, dynamic>;
    final payload = (body['data'] as Map<String, dynamic>?) ?? body;
    return ApiResponse<HomeworkAttachment>(
      success: true,
      data: HomeworkAttachment.fromApi(payload),
      message: body['message']?.toString() ?? 'Success',
      statusCode: response.statusCode,
    );
  }

  static Future<ApiResponse<HomeworkSubmission>> submitHomework({
    required String id,
    required String textAnswer,
    required List<HomeworkAttachment> attachments,
  }) async {
    final response = await ApiService.instance.post<dynamic>(
      endpoint: ApiService.HOMEWORK_SUBMIT.replaceFirst(':id', id),
      showLoader: false,
      data: {
        'textAnswer': textAnswer.trim().isEmpty
            ? ''
            : '<p>${textAnswer.trim()}</p>',
        'attachments': attachments.map((item) => item.toJson()).toList(),
      },
      fromJson: (json) => json,
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      return ApiResponse<HomeworkSubmission>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    final body = response.data as Map<String, dynamic>;
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      return ApiResponse<HomeworkSubmission>(
        success: false,
        message: 'Submission response not found.',
        statusCode: response.statusCode,
      );
    }

    return ApiResponse<HomeworkSubmission>(
      success: true,
      data: HomeworkSubmission.fromApi(data),
      message: body['message']?.toString() ?? 'Homework submitted',
      statusCode: response.statusCode,
    );
  }
}

enum LearnHomeworkTab {
  pending,
  completed;

  String get label {
    switch (this) {
      case LearnHomeworkTab.pending:
        return 'Pending';
      case LearnHomeworkTab.completed:
        return 'Completed';
    }
  }
}

enum LearnHomeworkStatus {
  pending('pending'),
  submitted('submitted'),
  graded('graded'),
  overdue('overdue');

  const LearnHomeworkStatus(this.apiValue);
  final String apiValue;

  String get label {
    switch (this) {
      case LearnHomeworkStatus.pending:
        return 'Pending';
      case LearnHomeworkStatus.submitted:
        return 'Submitted';
      case LearnHomeworkStatus.graded:
        return 'Graded';
      case LearnHomeworkStatus.overdue:
        return 'Overdue';
    }
  }
}

class LearnHomeworkModel {
  final String id;
  final String subject;
  final String subjectLabel;
  final String topic;
  final String title;
  final String description;
  final String dueDate;
  final String duration;
  final Color accent;
  final IconData icon;
  final Color iconBackground;
  final Color chipBackground;
  final LearnHomeworkStatus status;
  final String submittedDate;
  final String scoreLabel;
  final String scoreValue;
  final String submissionState;
  final String readTime;
  final String fileName;
  final String fileMeta;
  final String instructions;
  final int maxMarks;
  final bool allowLateSubmission;
  final List<HomeworkAttachment> attachments;
  final HomeworkSubmission? mySubmission;

  const LearnHomeworkModel({
    required this.id,
    required this.subject,
    required this.subjectLabel,
    required this.topic,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.duration,
    required this.accent,
    required this.icon,
    required this.iconBackground,
    required this.chipBackground,
    required this.status,
    required this.submittedDate,
    required this.scoreLabel,
    required this.scoreValue,
    required this.submissionState,
    required this.readTime,
    required this.fileName,
    required this.fileMeta,
    required this.instructions,
    required this.maxMarks,
    required this.allowLateSubmission,
    required this.attachments,
    required this.mySubmission,
  });

  factory LearnHomeworkModel.fromApi(Map<String, dynamic> json) {
    final subjectJson = json['subject'] as Map<String, dynamic>?;
    final lessonJson = json['lesson'] as Map<String, dynamic>?;
    final teacherJson = json['teacher'] as Map<String, dynamic>?;
    final status = _statusFromString(json['mySubmissionStatus']?.toString());
    final subjectName = subjectJson?['name']?.toString() ?? 'Homework';
    final palette = _paletteForSubject(subjectName);
    final dueAt = DateTime.tryParse(json['dueAt']?.toString() ?? '')?.toLocal();
    final attachmentsJson = json['attachments'] as List<dynamic>? ?? const [];
    final submissionJson = json['mySubmission'];
    final submission = submissionJson is Map<String, dynamic>
        ? HomeworkSubmission.fromApi(submissionJson)
        : null;

    return LearnHomeworkModel(
      id: json['_id']?.toString() ?? '',
      subject: subjectName,
      subjectLabel: subjectName.toUpperCase(),
      topic:
          lessonJson?['title']?.toString() ??
          teacherJson?['name']?.toString() ??
          '',
      title: json['title']?.toString() ?? 'Homework',
      description: _stripHtml(json['description']?.toString() ?? ''),
      dueDate: dueAt == null ? '-' : _formatDate(dueAt),
      duration: dueAt == null ? '' : _formatTime(dueAt),
      accent: palette.accent,
      icon: palette.icon,
      iconBackground: palette.iconBackground,
      chipBackground: palette.chipBackground,
      status: status,
      submittedDate: submission?.submittedDate ?? '-',
      scoreLabel: status == LearnHomeworkStatus.graded ? 'Marks' : 'Status',
      scoreValue: submission?.scoreValue ?? status.label,
      submissionState: status.label,
      readTime:
          '${((json['description']?.toString().length ?? 0) / 180).ceil().clamp(1, 9)} min read',
      fileName: submission?.attachments.isNotEmpty == true
          ? submission!.attachments.first.originalName
          : 'No file selected',
      fileMeta: submission?.attachments.isNotEmpty == true
          ? submission!.attachments.first.sizeLabel
          : 'Upload answer file',
      instructions: _stripHtml(json['description']?.toString() ?? ''),
      maxMarks: int.tryParse(json['maxMarks']?.toString() ?? '') ?? 0,
      allowLateSubmission: json['allowLateSubmission'] == true,
      attachments: attachmentsJson
          .whereType<Map<String, dynamic>>()
          .map(HomeworkAttachment.fromApi)
          .toList(),
      mySubmission: submission,
    );
  }

  bool get canSubmit {
    if (status == LearnHomeworkStatus.graded) {
      return false;
    }

    if (status == LearnHomeworkStatus.overdue) {
      return allowLateSubmission;
    }

    return true;
  }
}

class HomeworkAttachment {
  final String key;
  final String url;
  final String mimeType;
  final int size;
  final String originalName;

  const HomeworkAttachment({
    required this.key,
    required this.url,
    required this.mimeType,
    required this.size,
    required this.originalName,
  });

  factory HomeworkAttachment.fromApi(Map<String, dynamic> json) {
    return HomeworkAttachment(
      key: json['key']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      mimeType: json['mimeType']?.toString() ?? '',
      size: int.tryParse(json['size']?.toString() ?? '') ?? 0,
      originalName: json['originalName']?.toString() ?? 'attachment',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'url': url,
      'mimeType': mimeType,
      'size': size,
      'originalName': originalName,
    };
  }

  String get sizeLabel {
    if (size <= 0) {
      return 'Uploaded';
    }
    if (size >= 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / 1024).toStringAsFixed(1)} KB';
  }
}

class HomeworkSubmission {
  final String id;
  final String textAnswer;
  final List<HomeworkAttachment> attachments;
  final DateTime? submittedAt;
  final String status;
  final num? marks;
  final num? maxMarks;
  final num? percentage;
  final String feedback;

  const HomeworkSubmission({
    required this.id,
    required this.textAnswer,
    required this.attachments,
    required this.submittedAt,
    required this.status,
    required this.marks,
    required this.maxMarks,
    required this.percentage,
    required this.feedback,
  });

  factory HomeworkSubmission.fromApi(Map<String, dynamic> json) {
    final attachmentsJson = json['attachments'] as List<dynamic>? ?? const [];
    return HomeworkSubmission(
      id: json['_id']?.toString() ?? '',
      textAnswer: _stripHtml(json['textAnswer']?.toString() ?? ''),
      attachments: attachmentsJson
          .whereType<Map<String, dynamic>>()
          .map(HomeworkAttachment.fromApi)
          .toList(),
      submittedAt: DateTime.tryParse(
        json['submittedAt']?.toString() ?? '',
      )?.toLocal(),
      status: json['status']?.toString() ?? '',
      marks: num.tryParse(json['marks']?.toString() ?? ''),
      maxMarks: num.tryParse(json['maxMarks']?.toString() ?? ''),
      percentage: num.tryParse(json['percentage']?.toString() ?? ''),
      feedback: _stripHtml(json['feedback']?.toString() ?? ''),
    );
  }

  String get submittedDate =>
      submittedAt == null ? '-' : _formatDate(submittedAt!);

  String get scoreValue {
    if (marks != null && maxMarks != null) {
      return '$marks/$maxMarks';
    }
    if (percentage != null) {
      return '${percentage!.round()}%';
    }
    return status.isEmpty ? 'Submitted' : status.capitalizeFirst ?? status;
  }
}

class _HomeworkPalette {
  final Color accent;
  final IconData icon;
  final Color iconBackground;
  final Color chipBackground;

  const _HomeworkPalette({
    required this.accent,
    required this.icon,
    required this.iconBackground,
    required this.chipBackground,
  });
}

LearnHomeworkStatus _statusFromString(String? value) {
  switch (value) {
    case 'submitted':
      return LearnHomeworkStatus.submitted;
    case 'graded':
      return LearnHomeworkStatus.graded;
    case 'overdue':
      return LearnHomeworkStatus.overdue;
    case 'pending':
    default:
      return LearnHomeworkStatus.pending;
  }
}

_HomeworkPalette _paletteForSubject(String subject) {
  final lower = subject.toLowerCase();
  if (lower.contains('math')) {
    return const _HomeworkPalette(
      accent: Color(0xFF4A4FD9),
      icon: Icons.calculate_outlined,
      iconBackground: Color(0xFF6368F2),
      chipBackground: Color(0xFFE4E4FF),
    );
  }
  if (lower.contains('science')) {
    return const _HomeworkPalette(
      accent: Color(0xFFFFA31A),
      icon: Icons.science_outlined,
      iconBackground: Color(0xFFFFA31A),
      chipBackground: Color(0xFFFFF1DE),
    );
  }
  if (lower.contains('history')) {
    return const _HomeworkPalette(
      accent: Color(0xFF9A43E7),
      icon: Icons.history_edu_outlined,
      iconBackground: Color(0xFF9A43E7),
      chipBackground: Color(0xFFF2E4FF),
    );
  }
  return const _HomeworkPalette(
    accent: Color(0xFF7E2AD9),
    icon: Icons.assignment_outlined,
    iconBackground: Color(0xFF7E2AD9),
    chipBackground: Color(0xFFEAD7FF),
  );
}

String _stripHtml(String value) {
  return value
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String _formatTime(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}

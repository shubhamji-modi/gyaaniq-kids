import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/service/api_service.dart';

class PreviewResultController extends GetxController {
  final RxBool isLoading = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString errorMessage = ''.obs;
  final RxInt selectedTypeIndex = 0.obs;
  final RxInt selectedTabIndex = 0.obs;
  final RxList<QuizSubmitResultItem> results = <QuizSubmitResultItem>[].obs;

  int _page = 1;
  int _totalPages = 1;

  static const List<ResultTypeTab> typeTabs = [
    ResultTypeTab(label: 'Daily Quiz', type: ResultHistoryType.daily),
    ResultTypeTab(label: 'Practice Test', type: ResultHistoryType.practice),
    ResultTypeTab(label: 'Mock Test', type: ResultHistoryType.mock),
  ];

  static const List<ResultStatusTab> tabs = [
    ResultStatusTab(label: 'All', status: 'all'),
    ResultStatusTab(label: 'Completed', status: 'completed'),
    ResultStatusTab(label: 'In Progress', status: 'in_progress'),
  ];

  bool get hasMore => _page < _totalPages;

  String get selectedStatus => tabs[selectedTabIndex.value].status;

  ResultHistoryType get selectedType => typeTabs[selectedTypeIndex.value].type;

  @override
  void onInit() {
    super.onInit();
    loadResults();
  }

  Future<void> changeTab(int index) async {
    if (index == selectedTabIndex.value) {
      return;
    }
    selectedTabIndex.value = index;
    await loadResults(refresh: true);
  }

  Future<void> changeTypeTab(int index) async {
    if (index == selectedTypeIndex.value) {
      return;
    }
    selectedTypeIndex.value = index;
    selectedTabIndex.value = 0;
    await loadResults(refresh: true);
  }

  Future<void> loadResults({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _totalPages = 1;
    }

    if (_page == 1) {
      isLoading.value = true;
      errorMessage.value = '';
    } else {
      isLoadingMore.value = true;
    }

    final response = await QuizSubmitResultRepository.fetchResults(
      type: selectedType,
      status: selectedStatus,
      page: _page,
      limit: 20,
    );

    if (_page == 1) {
      isLoading.value = false;
    } else {
      isLoadingMore.value = false;
    }

    if (!response.success || response.data == null) {
      if (_page == 1) {
        results.clear();
        errorMessage.value = response.message;
      }
      return;
    }

    final payload = response.data!;
    errorMessage.value = '';
    _totalPages = payload.pagination.totalPages;

    if (_page == 1) {
      results.assignAll(payload.results);
    } else {
      results.addAll(payload.results);
    }
  }

  Future<void> loadMore() async {
    if (!hasMore || isLoading.value || isLoadingMore.value) {
      return;
    }
    _page++;
    await loadResults();
  }

  Future<ApiResponse<QuizAttemptFeedback>> loadFeedback(
    QuizSubmitResultItem item,
  ) {
    return QuizSubmitResultRepository.fetchFeedback(item);
  }
}

enum ResultHistoryType { daily, practice, mock }

class ResultTypeTab {
  const ResultTypeTab({required this.label, required this.type});

  final String label;
  final ResultHistoryType type;
}

class ResultStatusTab {
  const ResultStatusTab({required this.label, required this.status});

  final String label;
  final String status;
}

class QuizSubmitResultRepository {
  static Future<ApiResponse<QuizSubmitResultPage>> fetchResults({
    ResultHistoryType type = ResultHistoryType.practice,
    String status = 'all',
    String? classLevel,
    String? subject,
    int page = 1,
    int limit = 20,
  }) async {
    if (type == ResultHistoryType.daily) {
      return fetchDailyResults(status: status, page: page, limit: limit);
    }

    if (type == ResultHistoryType.mock) {
      return fetchMockResults(status: status, page: page, limit: limit);
    }

    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.GET_SUBMIT_RESULT,
      showLoader: false,
      fromJson: (json) => json,
      queryParameters: {
        if (status.isNotEmpty) 'status': status,
        if (classLevel != null && classLevel.isNotEmpty)
          'classLevel': classLevel,
        if (subject != null && subject.isNotEmpty) 'subject': subject,
        'page': page,
        'limit': limit,
      },
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      return ApiResponse<QuizSubmitResultPage>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    final body = response.data as Map<String, dynamic>;
    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    final resultsJson = data['attempts'] as List<dynamic>? ?? const [];
    final paginationJson =
        data['pagination'] as Map<String, dynamic>? ?? const {};

    return ApiResponse<QuizSubmitResultPage>(
      success: true,
      message: body['message']?.toString() ?? response.message,
      statusCode: response.statusCode,
      data: QuizSubmitResultPage(
        results: resultsJson
            .map(
              (item) =>
                  QuizSubmitResultItem.fromApi(item as Map<String, dynamic>),
            )
            .toList(),
        pagination: QuizSubmitPagination.fromApi(paginationJson),
      ),
    );
  }

  static Future<ApiResponse<QuizSubmitResultPage>> fetchDailyResults({
    String status = 'all',
    int page = 1,
    int limit = 20,
  }) async {
    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.DAILY_QUIZZS_HISTORY,
      showLoader: false,
      fromJson: (json) => json,
      queryParameters: {'page': page, 'limit': limit},
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      return ApiResponse<QuizSubmitResultPage>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    final body = response.data as Map<String, dynamic>;
    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    final attemptsJson = data['attempts'] as List<dynamic>? ?? const [];
    final paginationJson =
        data['pagination'] as Map<String, dynamic>? ?? const {};
    final items = attemptsJson
        .map(
          (item) =>
              QuizSubmitResultItem.fromDailyApi(item as Map<String, dynamic>),
        )
        .where((item) => status == 'all' || item.status == status)
        .toList();

    return ApiResponse<QuizSubmitResultPage>(
      success: true,
      message: body['message']?.toString() ?? response.message,
      statusCode: response.statusCode,
      data: QuizSubmitResultPage(
        results: items,
        pagination: QuizSubmitPagination.fromApi(paginationJson),
      ),
    );
  }

  static Future<ApiResponse<QuizSubmitResultPage>> fetchMockResults({
    String status = 'all',
    int page = 1,
    int limit = 20,
  }) async {
    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.MOCK_TEST_HISTORY,
      showLoader: false,
      fromJson: (json) => json,
      queryParameters: {'page': page, 'limit': limit},
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      return ApiResponse<QuizSubmitResultPage>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    final body = response.data as Map<String, dynamic>;
    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    final attemptsJson = data['attempts'] as List<dynamic>? ?? const [];
    final paginationJson =
        data['pagination'] as Map<String, dynamic>? ?? const {};
    final items = attemptsJson
        .map(
          (item) =>
              QuizSubmitResultItem.fromMockApi(item as Map<String, dynamic>),
        )
        .where((item) => status == 'all' || item.status == status)
        .toList();

    return ApiResponse<QuizSubmitResultPage>(
      success: true,
      message: body['message']?.toString() ?? response.message,
      statusCode: response.statusCode,
      data: QuizSubmitResultPage(
        results: items,
        pagination: QuizSubmitPagination.fromApi(paginationJson),
      ),
    );
  }

  static Future<ApiResponse<QuizAttemptFeedback>> fetchFeedback(
    QuizSubmitResultItem item,
  ) async {
    final endpoint = switch (item.type) {
      ResultHistoryType.daily => ApiService.DAILY_QUIZ_FEEDBACK,
      ResultHistoryType.practice => ApiService.PRACTICE_FEEDBACK,
      ResultHistoryType.mock => ApiService.MOCK_FEEDBACK,
    }.replaceFirst(':id', item.id);

    final response = await ApiService.instance.get<dynamic>(
      endpoint: endpoint,
      showLoader: false,
      fromJson: (json) => json,
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      return ApiResponse<QuizAttemptFeedback>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    final body = response.data as Map<String, dynamic>;
    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    return ApiResponse<QuizAttemptFeedback>(
      success: true,
      message: body['message']?.toString() ?? response.message,
      statusCode: response.statusCode,
      data: await _withQuestionDetails(
        QuizAttemptFeedback.fromApi(data, fallback: item),
        item,
      ),
    );
  }

  static Future<QuizAttemptFeedback> _withQuestionDetails(
    QuizAttemptFeedback feedback,
    QuizSubmitResultItem item,
  ) async {
    if (feedback.answers.every(
      (answer) => answer.questionText.isNotEmpty && answer.options.isNotEmpty,
    )) {
      return feedback;
    }

    final questionBank = await _fetchQuestionBank(item);
    if (questionBank.isEmpty) {
      return feedback;
    }

    return feedback.copyWith(
      answers: feedback.answers.map((answer) {
        final question = questionBank[answer.questionId];
        if (question == null) {
          return answer;
        }
        return answer.copyWith(
          questionText: answer.questionText.isEmpty
              ? question.questionText
              : answer.questionText,
          options: answer.options.isEmpty ? question.options : answer.options,
        );
      }).toList(),
    );
  }

  static Future<Map<String, _FeedbackQuestionSource>> _fetchQuestionBank(
    QuizSubmitResultItem item,
  ) async {
    final endpoint = switch (item.type) {
      ResultHistoryType.practice =>
        ApiService.FETCH_SINGLE_QUIZZES.replaceFirst(':id', item.quizId),
      ResultHistoryType.mock => ApiService.FETCH_MOCK_TEST.replaceFirst(
        ':id',
        item.quizId,
      ),
      ResultHistoryType.daily => ApiService.DAILY_QUIZZS,
    };

    if (item.type != ResultHistoryType.daily && item.quizId.isEmpty) {
      return const {};
    }

    final response = await ApiService.instance.get<dynamic>(
      endpoint: endpoint,
      showLoader: false,
      fromJson: (json) => json,
    );

    if (!response.success || response.data is! Map<String, dynamic>) {
      return const {};
    }

    final body = response.data as Map<String, dynamic>;
    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    if (item.type == ResultHistoryType.daily &&
        _safeText(data['_id']) != item.quizId) {
      return const {};
    }
    final questionsJson = data['questions'] as List<dynamic>? ?? const [];

    return {
      for (final question in questionsJson)
        if (question is Map<String, dynamic>)
          _safeText(question['_id']): _FeedbackQuestionSource.fromApi(question),
    };
  }
}

class _FeedbackQuestionSource {
  const _FeedbackQuestionSource({
    required this.questionText,
    required this.options,
  });

  final String questionText;
  final List<String> options;

  factory _FeedbackQuestionSource.fromApi(Map<String, dynamic> json) {
    return _FeedbackQuestionSource(
      questionText: _stripHtml(
        _safeText(
          json['questionText'],
          fallback: _safeText(json['text'], fallback: _safeText(json['title'])),
        ),
      ),
      options: (json['options'] as List<dynamic>? ?? const [])
          .map(_optionText)
          .toList(),
    );
  }
}

class QuizAttemptFeedback {
  const QuizAttemptFeedback({
    required this.title,
    required this.scoreText,
    required this.percentageText,
    required this.passed,
    required this.answers,
  });

  final String title;
  final String scoreText;
  final String percentageText;
  final bool passed;
  final List<QuizAttemptAnswerFeedback> answers;

  QuizAttemptFeedback copyWith({
    String? title,
    String? scoreText,
    String? percentageText,
    bool? passed,
    List<QuizAttemptAnswerFeedback>? answers,
  }) {
    return QuizAttemptFeedback(
      title: title ?? this.title,
      scoreText: scoreText ?? this.scoreText,
      percentageText: percentageText ?? this.percentageText,
      passed: passed ?? this.passed,
      answers: answers ?? this.answers,
    );
  }

  factory QuizAttemptFeedback.fromApi(
    Map<String, dynamic> json, {
    required QuizSubmitResultItem fallback,
  }) {
    final quiz = (json['quiz'] as Map<String, dynamic>?) ?? const {};
    final dailyQuiz = (json['dailyQuiz'] as Map<String, dynamic>?) ?? const {};
    final mockTest = (json['mockTest'] as Map<String, dynamic>?) ?? const {};
    final title = _safeText(
      quiz['title'],
      fallback: _safeText(
        mockTest['title'],
        fallback: fallback.lessonTitle.isEmpty
            ? _safeText(dailyQuiz['_id'], fallback: fallback.quizTitle)
            : fallback.lessonTitle,
      ),
    );
    final totalScore =
        (json['totalScore'] as num?)?.toInt() ?? fallback.totalScore;
    final maxScore = (json['maxScore'] as num?)?.toInt() ?? fallback.maxScore;
    final percentage =
        (json['percentage'] as num?)?.toDouble() ?? fallback.percentage;

    return QuizAttemptFeedback(
      title: title,
      scoreText: '$totalScore/$maxScore',
      percentageText: _formatPercentage(percentage),
      passed: json['passed'] == true,
      answers: (json['answers'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                QuizAttemptAnswerFeedback.fromApi(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class QuizAttemptAnswerFeedback {
  const QuizAttemptAnswerFeedback({
    required this.questionId,
    required this.questionText,
    required this.options,
    required this.selectedIndex,
    required this.correctIndex,
    required this.isCorrect,
    required this.marks,
    required this.marksAwarded,
  });

  final String questionId;
  final String questionText;
  final List<String> options;
  final int? selectedIndex;
  final int correctIndex;
  final bool isCorrect;
  final int marks;
  final int marksAwarded;

  QuizAttemptAnswerFeedback copyWith({
    String? questionId,
    String? questionText,
    List<String>? options,
    int? selectedIndex,
    int? correctIndex,
    bool? isCorrect,
    int? marks,
    int? marksAwarded,
  }) {
    return QuizAttemptAnswerFeedback(
      questionId: questionId ?? this.questionId,
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      correctIndex: correctIndex ?? this.correctIndex,
      isCorrect: isCorrect ?? this.isCorrect,
      marks: marks ?? this.marks,
      marksAwarded: marksAwarded ?? this.marksAwarded,
    );
  }

  factory QuizAttemptAnswerFeedback.fromApi(Map<String, dynamic> json) {
    final question = json['question'];
    final questionJson = question is Map<String, dynamic>
        ? question
        : <String, dynamic>{};
    final optionsJson =
        (json['options'] as List<dynamic>?) ??
        (json['optionTexts'] as List<dynamic>?) ??
        (questionJson['options'] as List<dynamic>?) ??
        (questionJson['optionTexts'] as List<dynamic>?) ??
        const [];

    return QuizAttemptAnswerFeedback(
      questionId: _safeText(
        questionJson['_id'],
        fallback: _safeText(question ?? json['questionId']),
      ),
      questionText: _stripHtml(
        _safeText(
          json['questionText'],
          fallback: _safeText(
            json['text'],
            fallback: _safeText(
              questionJson['questionText'],
              fallback: _safeText(questionJson['text']),
            ),
          ),
        ),
      ),
      options: optionsJson.map(_optionText).toList(),
      selectedIndex: (json['selectedIndex'] as num?)?.toInt(),
      correctIndex: (json['correctIndex'] as num?)?.toInt() ?? -1,
      isCorrect: json['isCorrect'] == true,
      marks: (json['marks'] as num?)?.toInt() ?? 0,
      marksAwarded: (json['marksAwarded'] as num?)?.toInt() ?? 0,
    );
  }

  String get selectedLabel =>
      selectedIndex == null ? 'Not answered' : _optionLabel(selectedIndex!);

  String get correctLabel =>
      correctIndex < 0 ? '-' : _optionLabel(correctIndex);

  String optionText(int index) {
    if (index < 0 || index >= options.length) {
      return '';
    }
    return options[index];
  }
}

class QuizSubmitResultPage {
  const QuizSubmitResultPage({required this.results, required this.pagination});

  final List<QuizSubmitResultItem> results;
  final QuizSubmitPagination pagination;
}

class QuizSubmitPagination {
  const QuizSubmitPagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  final int total;
  final int page;
  final int limit;
  final int totalPages;

  factory QuizSubmitPagination.fromApi(Map<String, dynamic> json) {
    return QuizSubmitPagination(
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

class QuizSubmitResultItem {
  const QuizSubmitResultItem({
    required this.id,
    required this.quizId,
    required this.quizTitle,
    required this.lessonId,
    required this.lessonTitle,
    required this.classLevel,
    required this.lessonOrder,
    required this.subjectId,
    required this.subjectName,
    required this.status,
    required this.totalScore,
    required this.maxScore,
    required this.percentage,
    required this.passed,
    required this.createdAt,
    required this.updatedAt,
    required this.type,
  });

  final String id;
  final String quizId;
  final String quizTitle;
  final String lessonId;
  final String lessonTitle;
  final String classLevel;
  final int lessonOrder;
  final String subjectId;
  final String subjectName;
  final String status;
  final int totalScore;
  final int maxScore;
  final double percentage;
  final bool passed;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final ResultHistoryType type;

  factory QuizSubmitResultItem.fromApi(Map<String, dynamic> json) {
    final quiz = (json['quiz'] as Map<String, dynamic>?) ?? const {};
    final lesson = (quiz['lesson'] as Map<String, dynamic>?) ?? const {};
    final subject = (quiz['subject'] as Map<String, dynamic>?) ?? const {};
    final passed = json['passed'] == true;

    return QuizSubmitResultItem(
      id: _safeText(json['_id']),
      quizId: _safeText(quiz['_id']),
      quizTitle: _safeText(quiz['title'], fallback: 'Untitled Quiz'),
      lessonId: _safeText(lesson['_id']),
      lessonTitle: _safeText(lesson['title'], fallback: 'Untitled Lesson'),
      classLevel: _safeText(
        quiz['classLevel'],
        fallback: _safeText(json['classLevel']),
      ),
      lessonOrder: (lesson['order'] as num?)?.toInt() ?? 0,
      subjectId: _safeText(subject['_id']),
      subjectName: _safeText(subject['name'], fallback: 'Subject'),
      status: passed ? 'completed' : 'in_progress',
      totalScore: (json['totalScore'] as num?)?.toInt() ?? 0,
      maxScore: (json['maxScore'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      passed: passed,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      type: ResultHistoryType.practice,
    );
  }

  factory QuizSubmitResultItem.fromDailyApi(Map<String, dynamic> json) {
    final dailyQuiz = (json['dailyQuiz'] as Map<String, dynamic>?) ?? const {};
    final passed = json['passed'] == true;
    final quizDate = _parseDate(json['date'] ?? dailyQuiz['date']);

    return QuizSubmitResultItem(
      id: _safeText(json['_id']),
      quizId: _safeText(dailyQuiz['_id']),
      quizTitle: 'Daily Quiz',
      lessonId: '',
      lessonTitle: 'Daily Quiz',
      classLevel: _safeText(
        json['classLevel'],
        fallback: _safeText(dailyQuiz['classLevel']),
      ),
      lessonOrder: 0,
      subjectId: '',
      subjectName: 'Daily Quiz',
      status: passed ? 'completed' : 'in_progress',
      totalScore: (json['totalScore'] as num?)?.toInt() ?? 0,
      maxScore:
          (json['maxScore'] as num?)?.toInt() ??
          (dailyQuiz['totalMarks'] as num?)?.toInt() ??
          0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      passed: passed,
      createdAt: _parseDate(json['createdAt']) ?? quizDate,
      updatedAt: _parseDate(json['updatedAt']),
      type: ResultHistoryType.daily,
    );
  }

  factory QuizSubmitResultItem.fromMockApi(Map<String, dynamic> json) {
    final mockTest = (json['mockTest'] as Map<String, dynamic>?) ?? const {};
    final passed = json['passed'] == true;

    return QuizSubmitResultItem(
      id: _safeText(json['_id']),
      quizId: _safeText(mockTest['_id']),
      quizTitle: _safeText(mockTest['title'], fallback: 'Mock Test'),
      lessonId: '',
      lessonTitle: _safeText(mockTest['title'], fallback: 'Mock Test'),
      classLevel: _safeText(
        json['classLevel'],
        fallback: _safeText(mockTest['classLevel']),
      ),
      lessonOrder: 0,
      subjectId: '',
      subjectName: 'Mock Test',
      status: passed ? 'completed' : 'in_progress',
      totalScore: (json['totalScore'] as num?)?.toInt() ?? 0,
      maxScore:
          (json['maxScore'] as num?)?.toInt() ??
          (mockTest['totalMarks'] as num?)?.toInt() ??
          0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      passed: passed,
      createdAt:
          _parseDate(json['submittedAt']) ?? _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      type: ResultHistoryType.mock,
    );
  }

  Color get accent =>
      isCompleted ? const Color(0xFF22A45D) : const Color(0xFF4A4FD9);

  Color get iconBackground =>
      isCompleted ? const Color(0xFFE8F7EE) : const Color(0xFFE7EBFF);

  IconData get icon =>
      isCompleted ? Icons.check_circle_rounded : Icons.hourglass_top_rounded;

  bool get isCompleted => status == 'completed';

  String get statusLabel => isCompleted ? 'Completed' : 'In Progress';

  String get meta =>
      classLevel.isEmpty ? subjectName : '$subjectName • $classLevel';

  String get dateLabel => _formatDate(createdAt ?? updatedAt);

  String get subtitle => 'Submitted on $dateLabel';

  String get lessonLabel => lessonOrder > 0 ? 'Lesson $lessonOrder' : 'Lesson';

  String get scoreText => '$totalScore/$maxScore';

  String get percentageText => _formatPercentage(percentage);
}

String _safeText(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}

String _formatDate(DateTime? date) {
  if (date == null) {
    return '-';
  }

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

String _formatPercentage(double value) {
  final rounded = value.truncateToDouble() == value
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
  return '$rounded%';
}

String _optionLabel(int index) {
  if (index < 0 || index > 25) {
    return '-';
  }
  return String.fromCharCode(65 + index);
}

String _optionText(dynamic value) {
  if (value is Map<String, dynamic>) {
    return _stripHtml(
      _safeText(
        value['text'],
        fallback: _safeText(
          value['optionText'],
          fallback: _safeText(
            value['label'],
            fallback: _safeText(value['value']),
          ),
        ),
      ),
    );
  }
  return _stripHtml(_safeText(value));
}

String _stripHtml(String value) {
  return value
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

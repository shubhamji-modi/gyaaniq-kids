class ExplanationQuota {
  const ExplanationQuota({
    required this.limit,
    required this.used,
    required this.remaining,
    required this.resetsAt,
  });

  final int limit;
  final int used;
  final int remaining;
  final String resetsAt;

  factory ExplanationQuota.fromApi(Map<String, dynamic> json) {
    return ExplanationQuota(
      limit: (json['limit'] as num?)?.toInt() ?? 5,
      used: (json['used'] as num?)?.toInt() ?? 0,
      remaining: (json['remaining'] as num?)?.toInt() ?? 0,
      resetsAt: json['resetsAt']?.toString() ?? '',
    );
  }
}

class ExplanationStyle {
  const ExplanationStyle({
    required this.key,
    required this.label,
    required this.hint,
  });

  final String key;
  final String label;
  final String hint;

  factory ExplanationStyle.fromApi(Map<String, dynamic> json) {
    return ExplanationStyle(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      hint: json['hint']?.toString() ?? '',
    );
  }
}

class QuestionExplanationData {
  const QuestionExplanationData({
    required this.questionId,
    required this.explanationId,
    required this.explanation,
    required this.style,
    required this.styleLabel,
    required this.author,
    required this.isYours,
    required this.position,
    required this.total,
    required this.canSeeAnother,
    required this.quota,
  });

  final String questionId;
  final String explanationId;
  final String explanation;
  final String style;
  final String styleLabel;
  final String author;
  final bool isYours;
  final int position;
  final int total;
  final bool canSeeAnother;
  final ExplanationQuota? quota;

  factory QuestionExplanationData.fromApi(Map<String, dynamic> json) {
    final quotaJson = json['quota'];
    return QuestionExplanationData(
      questionId: json['questionId']?.toString() ?? '',
      explanationId: json['explanationId']?.toString() ?? '',
      explanation: json['explanation']?.toString().trim() ?? '',
      style: json['style']?.toString() ?? '',
      styleLabel: json['styleLabel']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      isYours: json['isYours'] == true,
      position: (json['position'] as num?)?.toInt() ?? 1,
      total: (json['total'] as num?)?.toInt() ?? 1,
      canSeeAnother: json['canSeeAnother'] == true,
      quota: quotaJson is Map<String, dynamic>
          ? ExplanationQuota.fromApi(quotaJson)
          : null,
    );
  }
}

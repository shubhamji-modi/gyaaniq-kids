enum QuizRewardSource { dailyQuiz, practiceTest, mockTest }

class XpConfigData {
  const XpConfigData({
    this.dailyLoginXp = 0,
    this.dailyQuizAttemptXp = 0,
    this.dailyQuizPassBonusXp = 0,
    this.lessonCompleteXp = 0,
    this.regularQuizAttemptXp = 0,
    this.regularQuizPassBonusXp = 0,
    this.mockTestAttemptXp = 0,
    this.mockTestPassBonusXp = 0,
    this.homeworkSubmitXp = 0,
    this.homeworkGoodMarksBonusXp = 0,
    this.homeworkGoodMarksThreshold = 0,
    this.streakActivity = '',
  });

  final int dailyLoginXp;
  final int dailyQuizAttemptXp;
  final int dailyQuizPassBonusXp;
  final int lessonCompleteXp;
  final int regularQuizAttemptXp;
  final int regularQuizPassBonusXp;
  final int mockTestAttemptXp;
  final int mockTestPassBonusXp;
  final int homeworkSubmitXp;
  final int homeworkGoodMarksBonusXp;
  final int homeworkGoodMarksThreshold;
  final String streakActivity;

  factory XpConfigData.fromApi(Map<String, dynamic> json) {
    return XpConfigData(
      dailyLoginXp: _asInt(json['dailyLoginXp']),
      dailyQuizAttemptXp: _asInt(json['dailyQuizAttemptXp']),
      dailyQuizPassBonusXp: _asInt(json['dailyQuizPassBonusXp']),
      lessonCompleteXp: _asInt(json['lessonCompleteXp']),
      regularQuizAttemptXp: _asInt(json['regularQuizAttemptXp']),
      regularQuizPassBonusXp: _asInt(json['regularQuizPassBonusXp']),
      mockTestAttemptXp: _asInt(json['mockTestAttemptXp']),
      mockTestPassBonusXp: _asInt(json['mockTestPassBonusXp']),
      homeworkSubmitXp: _asInt(json['homeworkSubmitXp']),
      homeworkGoodMarksBonusXp: _asInt(json['homeworkGoodMarksBonusXp']),
      homeworkGoodMarksThreshold: _asInt(json['homeworkGoodMarksThreshold']),
      streakActivity: json['streakActivity']?.toString() ?? '',
    );
  }

  int quizXp({required QuizRewardSource source, required bool passed}) {
    switch (source) {
      case QuizRewardSource.dailyQuiz:
        return dailyQuizAttemptXp + (passed ? dailyQuizPassBonusXp : 0);
      case QuizRewardSource.practiceTest:
        return regularQuizAttemptXp + (passed ? regularQuizPassBonusXp : 0);
      case QuizRewardSource.mockTest:
        return mockTestAttemptXp + (passed ? mockTestPassBonusXp : 0);
    }
  }
}

int _asInt(dynamic value) => (value as num?)?.toInt() ?? 0;

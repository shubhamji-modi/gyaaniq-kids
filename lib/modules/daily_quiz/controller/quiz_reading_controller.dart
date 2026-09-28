import 'dart:async';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/service/question_translation_service.dart';
import 'question_answer_show_controller.dart';

/// A question and its options in the student's chosen language.
class TranslatedQuestion {
  const TranslatedQuestion({required this.question, required this.options});

  final String question;
  final List<String> options;
}

/// Reading aids on the quiz screen: text zoom and question translation.
///
/// Both are remembered across quizzes, so a student who reads in Hindi or
/// needs bigger text sets it once, not on every attempt. Kept apart from
/// [QuestionAnswerShowController] because none of it affects the attempt
/// itself — answers are stored by option index, whatever language is shown.
class QuizReadingController extends GetxController {
  static QuizReadingController get instance =>
      Get.isRegistered<QuizReadingController>()
      ? Get.find<QuizReadingController>()
      : Get.put(QuizReadingController(), permanent: true);

  static const List<double> textScales = [0.9, 1.0, 1.15, 1.3, 1.5];
  static const String _textScaleKey = 'quiz_text_scale';
  static const String _languageKey = 'quiz_translation_language';

  final _translationService = QuestionTranslationService.instance;

  final RxDouble textScale = 1.0.obs;

  /// The language questions are shown in; null shows the original English.
  final Rxn<QuizLanguage> language = Rxn<QuizLanguage>();
  final RxBool isPreparingLanguage = false.obs;
  final RxMap<String, TranslatedQuestion> _translations =
      <String, TranslatedQuestion>{}.obs;
  final RxMap<String, bool> _translating = <String, bool>{}.obs;

  /// Bumped on every language change so a background run for the previous
  /// language stops instead of filling the cache with stale work.
  int _generation = 0;
  late final Future<void> _prefsLoaded;

  @override
  void onInit() {
    super.onInit();
    _prefsLoaded = _loadPreferences();
    ever<int>(QuestionAnswerShowController.instance.currentQuestionIndex, (_) {
      final quiz = QuestionAnswerShowController.instance;
      if (quiz.totalQuestions > 0) {
        unawaited(_translateQuestion(quiz.currentQuestion, _generation));
      }
    });
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scale = prefs.getDouble(_textScaleKey);
      if (scale != null && textScales.contains(scale)) {
        textScale.value = scale;
      }
      final code = prefs.getString(_languageKey) ?? '';
      language.value = QuestionTranslationService.byCode(code);
    } catch (_) {
      // Preferences are a convenience; defaults are fine without them.
    }
  }

  Future<void> _save(Future<bool> Function(SharedPreferences) write) async {
    try {
      await write(await SharedPreferences.getInstance());
    } catch (_) {}
  }

  // ---- Zoom ----

  int get _scaleIndex {
    final index = textScales.indexOf(textScale.value);
    return index < 0 ? 1 : index;
  }

  bool get canZoomIn => _scaleIndex < textScales.length - 1;

  bool get canZoomOut => _scaleIndex > 0;

  String get textScaleLabel => '${(textScale.value * 100).round()}%';

  void zoomIn() => _setScale(_scaleIndex + 1);

  void zoomOut() => _setScale(_scaleIndex - 1);

  void _setScale(int index) {
    if (index < 0 || index >= textScales.length) {
      return;
    }
    textScale.value = textScales[index];
    unawaited(
      _save((prefs) => prefs.setDouble(_textScaleKey, textScale.value)),
    );
  }

  // ---- Translation ----

  bool get isTranslationOn => language.value != null;

  String _key(QuizQuestion question, QuizLanguage target) =>
      '${target.code}|${question.id}|${question.question}';

  /// The translation to show for [question], or null to show the original.
  TranslatedQuestion? translationFor(QuizQuestion question) {
    final target = language.value;
    if (target == null) {
      return null;
    }
    return _translations[_key(question, target)];
  }

  bool isTranslating(QuizQuestion question) {
    final target = language.value;
    return target != null && _translating[_key(question, target)] == true;
  }

  /// Called when the quiz screen opens. Resumes a remembered language only if
  /// its pack is already on the phone — a download is never started without
  /// the student asking for it.
  Future<void> onQuizOpened() async {
    await _prefsLoaded;
    final target = language.value;
    if (target == null) {
      return;
    }
    bool ready;
    try {
      ready = await _translationService.isLanguageReady(target);
    } catch (_) {
      ready = false;
    }
    if (!ready) {
      language.value = null;
      return;
    }
    unawaited(_translateQuiz(++_generation));
  }

  /// Switches the quiz to [target], or back to the original when null.
  Future<void> selectLanguage(QuizLanguage? target) async {
    final generation = ++_generation;
    if (target == null) {
      language.value = null;
      isPreparingLanguage.value = false;
      unawaited(_save((prefs) => prefs.remove(_languageKey)));
      return;
    }

    isPreparingLanguage.value = true;
    bool ready;
    try {
      ready = await _translationService.prepareLanguage(target);
    } catch (_) {
      ready = false;
    }
    if (generation != _generation) {
      return;
    }
    isPreparingLanguage.value = false;

    if (!ready) {
      Get.snackbar(
        'Translation unavailable',
        'Could not download ${target.label}. Check your internet connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    language.value = target;
    unawaited(_save((prefs) => prefs.setString(_languageKey, target.code)));
    unawaited(_translateQuiz(generation));
  }

  /// Translates the current question first, then the rest in the background
  /// so moving between questions shows the translation straight away.
  Future<void> _translateQuiz(int generation) async {
    final quiz = QuestionAnswerShowController.instance;
    if (quiz.totalQuestions == 0) {
      return;
    }
    final current = quiz.currentQuestionIndex.value;
    final order = [
      current,
      for (var i = 0; i < quiz.totalQuestions; i++)
        if (i != current) i,
    ];
    final questions = quiz.questions;
    for (final index in order) {
      if (generation != _generation || !identical(questions, quiz.questions)) {
        return;
      }
      await _translateQuestion(questions[index], generation);
    }
  }

  Future<void> _translateQuestion(QuizQuestion question, int generation) async {
    final target = language.value;
    if (target == null || generation != _generation) {
      return;
    }
    final key = _key(question, target);
    if (_translations.containsKey(key) || _translating[key] == true) {
      return;
    }

    _translating[key] = true;
    try {
      final results = await Future.wait([
        _translationService.translate(question.question, target),
        for (final option in question.options)
          _translationService.translate(option, target),
      ]);
      _translations[key] = TranslatedQuestion(
        question: results.first,
        options: results.sublist(1),
      );
    } catch (_) {
      // Leave it untranslated; the original stays on screen.
    } finally {
      _translating.remove(key);
    }
  }
}

import 'package:google_mlkit_translation/google_mlkit_translation.dart';

/// A language a quiz question can be translated into.
class QuizLanguage {
  const QuizLanguage({
    required this.language,
    required this.label,
    required this.nativeLabel,
  });

  final TranslateLanguage language;
  final String label;
  final String nativeLabel;

  String get code => language.bcpCode;
}

/// On-device (Google ML Kit) translation of quiz questions from English.
///
/// Each language pack (~30 MB) is downloaded once on first use and then
/// works offline, so there is no per-question network cost and no backend
/// dependency. Results are cached per language for the whole session.
class QuestionTranslationService {
  QuestionTranslationService._();

  static final QuestionTranslationService instance =
      QuestionTranslationService._();

  static const List<QuizLanguage> languages = [
    QuizLanguage(
      language: TranslateLanguage.hindi,
      label: 'Hindi',
      nativeLabel: 'हिन्दी',
    ),
    QuizLanguage(
      language: TranslateLanguage.bengali,
      label: 'Bengali',
      nativeLabel: 'বাংলা',
    ),
    QuizLanguage(
      language: TranslateLanguage.marathi,
      label: 'Marathi',
      nativeLabel: 'मराठी',
    ),
    QuizLanguage(
      language: TranslateLanguage.gujarati,
      label: 'Gujarati',
      nativeLabel: 'ગુજરાતી',
    ),
    QuizLanguage(
      language: TranslateLanguage.tamil,
      label: 'Tamil',
      nativeLabel: 'தமிழ்',
    ),
    QuizLanguage(
      language: TranslateLanguage.telugu,
      label: 'Telugu',
      nativeLabel: 'తెలుగు',
    ),
    QuizLanguage(
      language: TranslateLanguage.kannada,
      label: 'Kannada',
      nativeLabel: 'ಕನ್ನಡ',
    ),
    QuizLanguage(
      language: TranslateLanguage.urdu,
      label: 'Urdu',
      nativeLabel: 'اردو',
    ),
  ];

  static QuizLanguage? byCode(String code) {
    for (final language in languages) {
      if (language.code == code) {
        return language;
      }
    }
    return null;
  }

  /// Text with no letters at all ("56", "3/4", "x = 2y") is left as it is:
  /// translating it can only garble the maths.
  static final RegExp _hasWords = RegExp(r'[A-Za-z]{2,}');

  final OnDeviceTranslatorModelManager _modelManager =
      OnDeviceTranslatorModelManager();
  final Map<TranslateLanguage, OnDeviceTranslator> _translators = {};
  final Map<TranslateLanguage, Map<String, String>> _cache = {};

  Future<bool> isLanguageReady(QuizLanguage target) async {
    final results = await Future.wait([
      _modelManager.isModelDownloaded(TranslateLanguage.english.bcpCode),
      _modelManager.isModelDownloaded(target.code),
    ]);
    return results.every((ready) => ready);
  }

  /// Downloads the language packs the translation needs, if missing.
  ///
  /// Done through a first translation rather than
  /// [OnDeviceTranslatorModelManager.downloadModel]: on iOS that call never
  /// completes, because the plugin listens for ML Kit's "download finished"
  /// notification on the wrong object. A translation downloads both packs via
  /// the native completion callback, which works on both platforms. The
  /// timeout guarantees the student is never left on a spinner.
  Future<bool> prepareLanguage(QuizLanguage target) async {
    if (await isLanguageReady(target)) {
      return true;
    }
    await _translatorFor(
      target,
    ).translateText('Hello').timeout(const Duration(minutes: 3));
    return isLanguageReady(target);
  }

  OnDeviceTranslator _translatorFor(QuizLanguage target) =>
      _translators.putIfAbsent(
        target.language,
        () => OnDeviceTranslator(
          sourceLanguage: TranslateLanguage.english,
          targetLanguage: target.language,
        ),
      );

  Future<String> translate(String text, QuizLanguage target) async {
    final source = text.trim();
    if (source.isEmpty || !_hasWords.hasMatch(source)) {
      return text;
    }

    final cache = _cache.putIfAbsent(target.language, () => {});
    final cached = cache[source];
    if (cached != null) {
      return cached;
    }

    final translated = (await _translatorFor(
      target,
    ).translateText(source).timeout(const Duration(seconds: 30))).trim();
    final result = translated.isEmpty ? source : translated;
    cache[source] = result;
    return result;
  }
}

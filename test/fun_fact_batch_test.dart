import 'package:flutter_test/flutter_test.dart';
import 'package:edupath_learning/modules/fun_fact/controller/fun_fact_controller.dart';

void main() {
  final urls = List.generate(5, (i) => 'https://example.com/$i.png');

  group('FunFactBatch resume', () {
    test('a fresh batch starts at the first fact', () {
      const batch = FunFactBatch(urls: ['a', 'b']);
      expect(batch.resumeIndex, 0);
      expect(batch.isCompleted, isFalse);
    });

    test('watching 3 of 5 resumes on the 4th', () {
      final batch = FunFactBatch(urls: urls, watchedCount: 3);
      expect(batch.resumeIndex, 3);
      expect(batch.isCompleted, isFalse);
    });

    test('the ring stays coloured until every fact is watched', () {
      for (var watched = 0; watched < 5; watched++) {
        expect(
          FunFactBatch(urls: urls, watchedCount: watched).isCompleted,
          isFalse,
          reason: '$watched of 5 watched must not grey the ring',
        );
      }
      expect(FunFactBatch(urls: urls, watchedCount: 5).isCompleted, isTrue);
    });

    test('a finished batch replays from the top and stays grey', () {
      final batch = FunFactBatch(urls: urls, watchedCount: 5);
      expect(batch.resumeIndex, 0);
      expect(batch.isCompleted, isTrue);
    });

    test('an empty batch is never complete', () {
      const batch = FunFactBatch(urls: [], watchedCount: 0);
      expect(batch.isCompleted, isFalse);
    });
  });

  group('FunFactController.subjectCategoryFor', () {
    test('maps syllabus titles onto the server enum', () {
      expect(FunFactController.subjectCategoryFor('Mathematics'), 'Mathematics');
      expect(FunFactController.subjectCategoryFor('Maths'), 'Mathematics');
      expect(FunFactController.subjectCategoryFor('Science'), 'Science');
      expect(FunFactController.subjectCategoryFor('EVS'), 'Science');
      expect(FunFactController.subjectCategoryFor('English'), 'English');
      expect(FunFactController.subjectCategoryFor('Hindi'), 'Hindi');
      expect(
        FunFactController.subjectCategoryFor('Social Science'),
        'Social Studies',
      );
      expect(FunFactController.subjectCategoryFor('History'), 'Social Studies');
      expect(
        FunFactController.subjectCategoryFor('Computer'),
        'Computer Science',
      );
    });

    test('an unknown subject sends no filter rather than a bad enum', () {
      expect(FunFactController.subjectCategoryFor('Sanskrit'), isNull);
      expect(FunFactController.subjectCategoryFor(''), isNull);
    });
  });
}

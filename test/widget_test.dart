import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:edupath_learning/modules/onboard/views/onboard_view.dart';

void main() {
  testWidgets('Onboarding renders first page content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: OnboardView(),
      ),
    );

    expect(find.text('EduPath'), findsOneWidget);
    expect(find.text('Welcome to Your'), findsOneWidget);
    expect(find.text('Learning Journey'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });
}

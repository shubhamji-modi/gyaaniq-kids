import 'package:edupath_learning/core/widgets/math_html_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, String html) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: MathHtmlText(html)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(r'renders inline $...$ math as a Math widget', (tester) async {
    await pump(
      tester,
      r'<strong>Formula:</strong> Perimeter = $2 \times (\text{length} + \text{breadth})$',
    );

    // The bold label stays as text; the formula becomes a real Math widget
    // instead of the raw "$2 \times ..." delimiters.
    expect(find.byType(Math), findsOneWidget);
    expect(find.textContaining(r'\times'), findsNothing);
  });

  testWidgets(r'renders display $$...$$ math', (tester) async {
    await pump(tester, r'Answer: $$length = 5$$');
    expect(find.byType(Math), findsOneWidget);
  });

  testWidgets('handles multiple formulae in one answer', (tester) async {
    await pump(
      tester,
      r'Step 1: $14 = 2 \times (length + 2)$ then $7 = length + 2$',
    );
    expect(find.byType(Math), findsNWidgets(2));
  });

  testWidgets('plain HTML with no math still renders', (tester) async {
    await pump(tester, '<strong>Given:</strong> a rectangle');
    expect(find.byType(Math), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

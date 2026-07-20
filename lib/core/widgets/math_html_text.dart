import 'package:flutter/widgets.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:html/dom.dart' as dom;

/// Renders an answer that mixes HTML (bold, lists, line breaks) with inline
/// LaTeX math, the way the authoring tool sends it.
///
/// The API embeds formulae as TeX delimited by `$...$` / `$$...$$` (and the
/// `\(...\)` / `\[...\]` variants). Plain [HtmlWidget] prints those delimiters
/// verbatim — e.g. `$2 \times (\text{length})$` — so here we first rewrite each
/// math span into a private `<tex>` element, then a custom [WidgetFactory]
/// swaps that element for a natively-rendered [Math] widget, inline with the
/// surrounding text.
class MathHtmlText extends StatelessWidget {
  const MathHtmlText(this.html, {super.key, this.textStyle});

  final String html;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return HtmlWidget(
      _mathToTex(html),
      textStyle: textStyle,
      factoryBuilder: () => _MathWidgetFactory(textStyle),
      customStylesBuilder: _spacing,
    );
  }
}

/// Opens up point-by-point answers so they don't read as one dense block.
///
/// Many textbook answers arrive as a two-column table (term → meaning) or a
/// list; the default rendering packs the rows tight. A little vertical padding
/// on each cell/item — plus a gap between the two table columns — gives every
/// point room to breathe.
StylesMap? _spacing(dom.Element element) {
  switch (element.localName) {
    case 'td':
    case 'th':
      return const {
        'padding-top': '8px',
        'padding-bottom': '8px',
        'padding-right': '14px',
        'vertical-align': 'top',
      };
    case 'li':
      return const {'padding-bottom': '10px'};
    case 'p':
      return const {'margin-bottom': '12px'};
    default:
      return null;
  }
}

/// Rewrites TeX spans into `<tex>` elements (display math carries `d="1"`).
///
/// Display delimiters are handled before inline ones so `$$…$$` is not chopped
/// into two empty inline spans by the `$…$` pass.
String _mathToTex(String input) {
  String out = input;

  String tag(Match m, {required bool display}) {
    final latex = _escapeHtml((m.group(1) ?? '').trim());
    return display ? '<tex d="1">$latex</tex>' : '<tex>$latex</tex>';
  }

  // $$ ... $$  and  \[ ... \]  → display math
  out = out.replaceAllMapped(
    RegExp(r'\$\$(.+?)\$\$', dotAll: true),
    (m) => tag(m, display: true),
  );
  out = out.replaceAllMapped(
    RegExp(r'\\\[(.+?)\\\]', dotAll: true),
    (m) => tag(m, display: true),
  );

  // $ ... $  and  \( ... \)  → inline math. `[^$]` keeps a single delimiter
  // from swallowing across expressions.
  out = out.replaceAllMapped(
    RegExp(r'\$([^\$]+?)\$', dotAll: true),
    (m) => tag(m, display: false),
  );
  out = out.replaceAllMapped(
    RegExp(r'\\\((.+?)\\\)', dotAll: true),
    (m) => tag(m, display: false),
  );

  return out;
}

/// Escapes the characters that would otherwise be read as HTML markup, so the
/// LaTeX survives parsing intact and comes back verbatim via `element.text`.
String _escapeHtml(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

class _MathWidgetFactory extends WidgetFactory {
  _MathWidgetFactory(this.textStyle);

  final TextStyle? textStyle;

  @override
  void parse(BuildTree tree) {
    if (tree.element.localName == 'tex') {
      final bool display = tree.element.attributes['d'] == '1';
      tree.register(
        BuildOp(
          debugLabel: 'tex',
          onParsed: (t) {
            final String latex = t.element.text;
            final replacement = t.parent.sub();
            replacement.append(
              WidgetBit.inline(
                replacement,
                Math.tex(
                  latex,
                  mathStyle: display ? MathStyle.display : MathStyle.text,
                  textStyle: textStyle,
                  // Never let a malformed formula blank the answer — fall back
                  // to the raw TeX so the student still sees something.
                  onErrorFallback: (_) => Text(latex, style: textStyle),
                ),
                alignment: PlaceholderAlignment.middle,
              ),
            );
            return replacement;
          },
        ),
      );
      return;
    }
    super.parse(tree);
  }
}

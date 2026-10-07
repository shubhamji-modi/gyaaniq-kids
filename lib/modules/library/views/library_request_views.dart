import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/appcolors.dart';
import '../data/library_models.dart';
import '../data/library_repository.dart';
import 'library_widgets.dart';

/// What the request form hands back to the Library.
class LibraryRequestOutcome {
  const LibraryRequestOutcome({
    required this.message,
    required this.lesson,
    required this.alreadyExists,
  });

  final String message;
  final LibraryLesson? lesson;

  /// The chapter was there already: the student now follows it and the
  /// Library should simply open it — this is never an error.
  final bool alreadyExists;
}

/// "Request a lesson": book + subject + chapter + name (+ note).
class LibraryRequestViews extends StatefulWidget {
  const LibraryRequestViews({
    super.key,
    required this.meta,
    this.initialPublication,
    this.initialSubject,
    this.initialChapter,
    this.initialTitle = '',
    this.onPublicationListed,
  });

  final LibraryMeta meta;
  final LibraryRef? initialPublication;
  final LibraryRef? initialSubject;
  final int? initialChapter;
  final String initialTitle;

  /// A publication the student can now pick (e.g. after a `409` telling them
  /// it is already listed) — lets the Library add it to its filter.
  final ValueChanged<LibraryRef>? onPublicationListed;

  @override
  State<LibraryRequestViews> createState() => _LibraryRequestViewsState();
}

class _LibraryRequestViewsState extends State<LibraryRequestViews> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _chapter = TextEditingController(
    text: widget.initialChapter?.toString() ?? '',
  );
  late final TextEditingController _title = TextEditingController(
    text: widget.initialTitle,
  );
  final TextEditingController _note = TextEditingController();

  late final List<LibraryRef> _publications = [...widget.meta.publications];
  LibraryRef? _publication;
  LibraryRef? _subject;
  bool _sending = false;
  Map<String, String> _serverErrors = const {};
  String _formError = '';

  LibraryRules get rules => widget.meta.rules;

  @override
  void initState() {
    super.initState();
    _publication = widget.initialPublication;
    _subject =
        widget.initialSubject ??
        (widget.meta.subjects.length == 1 ? widget.meta.subjects.first : null);
  }

  @override
  void dispose() {
    _chapter.dispose();
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  void _clearServerError(String field) {
    if (_serverErrors.containsKey(field) || _formError.isNotEmpty) {
      setState(() {
        _serverErrors = Map.of(_serverErrors)..remove(field);
        _formError = '';
      });
    }
  }

  Future<void> _pickPublication() async {
    final picked = await showModalBottomSheet<LibraryRef>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PublicationPickerSheet(
        initial: _publications,
        selected: _publication,
      ),
    );
    if (picked == null) return;
    if (picked.id.isEmpty) {
      // "Not listed?" from inside the picker.
      await _requestPublication();
      return;
    }
    setState(() {
      _publication = picked;
      if (!_publications.contains(picked)) _publications.add(picked);
    });
    _clearServerError('publicationId');
  }

  Future<void> _pickSubject() async {
    final picked = await showModalBottomSheet<LibraryRef>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                'Subject',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
            for (final s in widget.meta.subjects)
              ListTile(
                title: Text(
                  s.name,
                  style: TextStyle(
                    fontWeight: s == _subject
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: s == _subject
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
                trailing: s == _subject
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(s),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    setState(() => _subject = picked);
    _clearServerError('subjectId');
  }

  Future<void> _requestPublication() async {
    final listed = await showModalBottomSheet<LibraryRef>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => LibraryPublicationRequestSheet(noteMax: rules.noteMax),
    );
    // A 409 "already in the list" hands the publication back: select it.
    if (listed != null && listed.id.isNotEmpty) {
      setState(() {
        if (!_publications.contains(listed)) _publications.add(listed);
        _publication = listed;
      });
      widget.onPublicationListed?.call(listed);
    }
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _serverErrors = const {};
      _formError = '';
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_publication == null || _subject == null) {
      setState(() {
        _formError = _publication == null
            ? 'Choose the publication (book).'
            : 'Choose the subject.';
      });
      return;
    }

    setState(() => _sending = true);
    final result = await LibraryRepository.requestLesson(
      publicationId: _publication!.id,
      subjectId: _subject!.id,
      chapterNumber: int.parse(_chapter.text.trim()),
      title: _title.text,
      note: _note.text,
    );
    if (!mounted) return;
    setState(() => _sending = false);

    if (result.ok) {
      Get.back(
        result: LibraryRequestOutcome(
          message: result.message,
          lesson: result.data,
          alreadyExists: result.statusCode == 200,
        ),
      );
      return;
    }

    final fieldErrors = result.fieldErrors;
    setState(() {
      _serverErrors = fieldErrors;
      // Field errors sit next to their field; anything else goes on top.
      final unplaced = fieldErrors.keys.where(
        (k) => !const {
          'publicationId',
          'subjectId',
          'chapterNumber',
          'title',
          'note',
        }.contains(k),
      );
      _formError = fieldErrors.isEmpty || unplaced.isNotEmpty
          ? result.displayMessage
          : '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final quota = widget.meta.requests;
    return Scaffold(
      backgroundColor: LibraryPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            const LibraryTopBar(title: 'Request a lesson'),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPale,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Tell us which lesson from your book you need. '
                        'Once an admin approves it, you can photograph its '
                        'pages and we will turn them into notes, Q&A and a quiz '
                        'for everyone in your class.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _FieldLabel('Publication'),
                    _PickerField(
                      value: _publication?.name,
                      hint: 'Choose the book publisher',
                      error: _serverErrors['publicationId'],
                      onTap: _pickPublication,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _requestPublication,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text(
                          'Not listed? Request it',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _FieldLabel('Subject'),
                    _PickerField(
                      value: _subject?.name,
                      hint: 'Choose the subject',
                      error: _serverErrors['subjectId'],
                      onTap: _pickSubject,
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel('Chapter no.'),
                    TextFormField(
                      controller: _chapter,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      onChanged: (_) => _clearServerError('chapterNumber'),
                      decoration: _inputDecoration(
                        hint: 'e.g. 4',
                        error: _serverErrors['chapterNumber'],
                      ),
                      validator: (v) {
                        final n = int.tryParse(v?.trim() ?? '');
                        if (n == null) return 'Enter the chapter number.';
                        if (n < 1 || n > rules.chapterMax) {
                          return 'Chapter number must be 1–${rules.chapterMax}.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel('Lesson name'),
                    TextFormField(
                      controller: _title,
                      maxLength: rules.titleMax,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) => _clearServerError('title'),
                      decoration: _inputDecoration(
                        hint: 'e.g. Fractions',
                        error: _serverErrors['title'],
                      ),
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) return 'Enter the lesson name.';
                        if (t.length > rules.titleMax) {
                          return 'Keep it under ${rules.titleMax} characters.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 6),
                    _FieldLabel('Note (optional)'),
                    TextFormField(
                      controller: _note,
                      maxLength: rules.noteMax,
                      maxLines: 3,
                      minLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) => _clearServerError('note'),
                      decoration: _inputDecoration(
                        hint: 'Anything that helps find the right lesson',
                        error: _serverErrors['note'],
                      ),
                    ),
                    if (_formError.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: LibraryPalette.redSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formError,
                          style: const TextStyle(
                            color: LibraryPalette.red,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Text(
                      'Requests left today: ${quota.remaining} of ${quota.limit}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: quota.remaining > 0
                            ? AppColors.textMuted
                            : LibraryPalette.red,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (quota.remaining <= 0)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'If the lesson already exists you can still follow '
                          'it — that does not use a request.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    LibraryPrimaryButton(
                      label: 'Send request',
                      icon: Icons.send_rounded,
                      busy: _sending,
                      expand: true,
                      onPressed: _send,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration({required String hint, String? error}) {
  OutlineInputBorder border(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: c),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textMuted6, fontSize: 14),
    errorText: error,
    errorMaxLines: 3,
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: border(LibraryPalette.border),
    focusedBorder: border(AppColors.primary),
    errorBorder: border(LibraryPalette.red),
    focusedErrorBorder: border(LibraryPalette.red),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.value,
    required this.hint,
    required this.onTap,
    this.error,
  });

  final String? value;
  final String hint;
  final String? error;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: _inputDecoration(
          hint: hint,
          error: error,
        ).copyWith(suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded)),
        isEmpty: value == null,
        child: Text(
          value ?? '',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Publication picker with a live search (`GET /publications?q=`). Returns
/// [LibraryRef.empty] when the student taps "Not listed?".
class _PublicationPickerSheet extends StatefulWidget {
  const _PublicationPickerSheet({required this.initial, this.selected});

  final List<LibraryRef> initial;
  final LibraryRef? selected;

  @override
  State<_PublicationPickerSheet> createState() =>
      _PublicationPickerSheetState();
}

class _PublicationPickerSheetState extends State<_PublicationPickerSheet> {
  late List<LibraryRef> _results = widget.initial;
  Timer? _debounce;
  bool _loading = false;
  int _generation = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    final query = q.trim();
    if (query.isEmpty) {
      setState(() {
        _results = widget.initial;
        _loading = false;
      });
      return;
    }
    // Show local matches straight away, then whatever the server finds.
    setState(() {
      _results = widget.initial
          .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
      _loading = true;
    });
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final generation = ++_generation;
      final result = await LibraryRepository.searchPublications(query);
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        if (result.ok && result.data != null) _results = result.data!;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Publication',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  autofocus: widget.initial.length > 8,
                  onChanged: _onChanged,
                  decoration: InputDecoration(
                    hintText: 'Search publications',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _loading
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.neutralSurface2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final p in _results)
                      _PublicationTile(
                        publication: p,
                        selected: p == widget.selected,
                        onTap: () => Navigator.of(context).pop(p),
                      ),
                    if (_results.isEmpty && !_loading)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 18, 20, 4),
                        child: Text(
                          'No publication found.',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    ListTile(
                      leading: const Icon(
                        Icons.add_circle_outline_rounded,
                        color: AppColors.primary,
                      ),
                      title: const Text(
                        'Not listed? Request it',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onTap: () => Navigator.of(context).pop(LibraryRef.empty),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One listed publication, drawn as a tinted card so the available ones stand
/// out from the "Not listed?" action below them.
class _PublicationTile extends StatelessWidget {
  const _PublicationTile({
    required this.publication,
    required this.selected,
    required this.onTap,
  });

  final LibraryRef publication;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Material(
        color: selected ? AppColors.primarySoft : AppColors.primaryPale,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.primaryTint,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    publication.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Request a publication" + the student's earlier publication requests.
///
/// Pops with the listed publication when the server answers `409` with
/// `error.publication` (it is already in the list — select it).
class LibraryPublicationRequestSheet extends StatefulWidget {
  const LibraryPublicationRequestSheet({super.key, required this.noteMax});

  final int noteMax;

  @override
  State<LibraryPublicationRequestSheet> createState() =>
      _LibraryPublicationRequestSheetState();
}

class _LibraryPublicationRequestSheetState
    extends State<LibraryPublicationRequestSheet> {
  final _name = TextEditingController();
  final _note = TextEditingController();
  bool _sending = false;
  String _error = '';
  String _success = '';
  List<LibraryPublicationRequest> _requests = const [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    final result = await LibraryRepository.fetchPublicationRequests();
    if (!mounted || !result.ok) return;
    setState(() => _requests = result.data ?? const []);
  }

  Future<void> _send() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter the publication name.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _error = '';
      _success = '';
    });
    final result = await LibraryRepository.requestPublication(
      name: name,
      note: _note.text,
    );
    if (!mounted) return;
    setState(() => _sending = false);

    if (result.ok) {
      // 201 new request · 200 someone already asked — now following it.
      setState(() {
        _success = result.message.isNotEmpty && result.message != 'Success'
            ? result.message
            : "Request sent! We'll tell you when it is added.";
        _name.clear();
        _note.clear();
      });
      unawaited(_loadRequests());
      return;
    }

    final listed = result.errorMap['publication'];
    if (result.statusCode == 409 && listed != null) {
      final pub = LibraryRef.fromApi(listed);
      if (pub.id.isNotEmpty) {
        showLibrarySnack(result.displayMessage);
        Navigator.of(context).pop(pub);
        return;
      }
    }
    final fieldErrors = result.fieldErrors;
    setState(() {
      _error = fieldErrors.isNotEmpty
          ? fieldErrors.values.join('\n')
          : result.displayMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            children: [
              const Text(
                'Request a publication',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Is your book missing from the list? Tell us its name and an '
                'admin will add it.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                maxLength: 80,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration(hint: 'e.g. Oxford Maths'),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _note,
                maxLength: widget.noteMax,
                maxLines: 2,
                decoration: _inputDecoration(hint: 'Note (optional)'),
              ),
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    _error,
                    style: const TextStyle(
                      color: LibraryPalette.red,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (_success.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    _success,
                    style: const TextStyle(
                      color: LibraryPalette.green,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              LibraryPrimaryButton(
                label: 'Send request',
                busy: _sending,
                expand: true,
                onPressed: _send,
              ),
              if (_requests.isNotEmpty) ...[
                const SizedBox(height: 22),
                const Text(
                  'Publication requests',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                for (final r in _requests) _PublicationRequestTile(request: r),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PublicationRequestTile extends StatelessWidget {
  const _PublicationRequestTile({required this.request});

  final LibraryPublicationRequest request;

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (request.status) {
      'added' => ('Added', LibraryPalette.green, LibraryPalette.greenSoft),
      'rejected' => ('Not added', LibraryPalette.red, LibraryPalette.redSoft),
      _ => ('Pending', LibraryPalette.amber, LibraryPalette.amberSoft),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LibraryPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (request.status == 'rejected' && request.reason.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              request.reason,
              style: const TextStyle(color: LibraryPalette.red, fontSize: 12),
            ),
          ],
          if (request.followerCount > 1) ...[
            const SizedBox(height: 4),
            Text(
              '${request.followerCount} students asked for this',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

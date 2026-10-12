import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/appcolors.dart';
import '../data/library_models.dart';
import '../data/library_repository.dart';
import 'library_widgets.dart';

/// Choosing which book a chapter comes from.
///
/// This is the one picker shared by every Library flow. It searches the
/// server's publication list, and folds "my book isn't here" into the same
/// sheet so the student never has to know those are two different things:
/// asking for a book hands back the book itself once an admin lists it.
///
/// Returns the chosen publication, or `null` if the student backed out.
/// [onListed] fires when a book the student asked for turns out to be listed
/// already, so callers can remember it.
Future<LibraryRef?> showLibraryPublicationPicker(
  BuildContext context, {
  required List<LibraryRef> known,
  required LibraryRef? selected,
  required int noteMax,
  ValueChanged<LibraryRef>? onListed,
}) async {
  final picked = await showModalBottomSheet<LibraryRef>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _PublicationPickerSheet(initial: known, selected: selected),
  );
  if (picked == null) return null;
  if (picked.id.isNotEmpty) return picked;

  // "My book isn't here" — ask for it, and take it straight back if the
  // server says it was listed all along.
  if (!context.mounted) return null;
  final listed = await showModalBottomSheet<LibraryRef>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => LibraryPublicationRequestSheet(noteMax: noteMax),
  );
  if (listed == null || listed.id.isEmpty) return null;
  onListed?.call(listed);
  return listed;
}

/// Publication picker with a live search (`GET /publications?q=`). Returns
/// [LibraryRef.empty] when the student taps "My book isn't here".
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
                    'Which book?',
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
                    hintText: 'Type your book name',
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
                          "We couldn't find that book.",
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    ListTile(
                      leading: const Icon(
                        Icons.add_circle_outline_rounded,
                        color: AppColors.primary,
                      ),
                      title: const Text(
                        "My book isn't here",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: const Text(
                        'Tell us its name and we will add it',
                        style: TextStyle(fontSize: 12),
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
/// out from the "My book isn't here" action below them.
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

/// "Add my book" + the student's earlier book requests.
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
      setState(() => _error = 'Type your book name first.');
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
            : "Sent! We'll tell you when your book is added.";
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
                'Add my book',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Can't see your book in the list? Type its name and a teacher "
                'will add it.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                maxLength: 80,
                textCapitalization: TextCapitalization.words,
                decoration: libraryInputDecoration(hint: 'e.g. Oxford Maths'),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _note,
                maxLength: widget.noteMax,
                maxLines: 2,
                decoration: libraryInputDecoration(
                  hint: 'Anything else? (you can skip this)',
                ),
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
                label: 'Send',
                busy: _sending,
                expand: true,
                onPressed: _send,
              ),
              if (_requests.isNotEmpty) ...[
                const SizedBox(height: 22),
                const Text(
                  'Books you asked for',
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
      _ => ('Waiting', LibraryPalette.amber, LibraryPalette.amberSoft),
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

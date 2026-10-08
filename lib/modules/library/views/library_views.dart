import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/appcolors.dart';
import '../../dashboard_vc/views/class_change_sheet.dart';
import '../controller/library_controller.dart';
import '../data/library_models.dart';
import '../library_navigation.dart';
import 'library_request_views.dart';
import 'library_widgets.dart';

/// Student Library: lessons of the student's class from other publications
/// (S. Chand, RD Sharma, …), shared by students and checked by an admin.
class LibraryViews extends StatefulWidget {
  const LibraryViews({super.key});

  @override
  State<LibraryViews> createState() => _LibraryViewsState();
}

class _LibraryViewsState extends State<LibraryViews>
    with SingleTickerProviderStateMixin {
  late final LibraryController controller;
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    controller = Get.put(LibraryController());
    _tabs = TabController(length: 4, vsync: this);
    _tabs.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    Get.delete<LibraryController>();
    super.dispose();
  }

  LibraryLessonList _listFor(int index) {
    switch (index) {
      case 1:
        return controller.myRequests;
      case 2:
        return controller.myUploads;
      case 3:
        return controller.following;
      default:
        return controller.browse;
    }
  }

  void _onTabChanged() {
    if (_tabs.indexIsChanging) return;
    final list = _listFor(_tabs.index);
    if (!list.loadedOnce && !list.isLoading.value) list.reload();
  }

  // -- Row actions. Each one re-fetches on return: `myState` moves on as
  //    other students and admins act.

  Future<void> _openLesson(LibraryLesson lesson) async {
    await LibraryNavigation.openLesson(lesson.id);
    unawaited(controller.refreshAfterReturn());
  }

  Future<void> _upload(LibraryLesson lesson) async {
    await LibraryNavigation.startUpload(lesson.id);
    unawaited(controller.refreshAfterReturn());
  }

  Future<void> _continue(LibraryLesson lesson) async {
    final sid = lesson.mySessionId;
    if (sid == null) {
      await _upload(lesson);
      return;
    }
    await LibraryNavigation.openSession(sid);
    unawaited(controller.refreshAfterReturn());
  }

  Future<void> _toggleFollow(LibraryLesson lesson) async {
    final result = await controller.toggleFollow(lesson);
    showLibrarySnack(
      result.ok
          ? (result.message.isNotEmpty && result.message != 'Success'
          ? result.message
          : (lesson.isFollowing
          ? 'You will no longer get updates for this lesson.'
          : "We'll notify you when it's ready."))
          : result.displayMessage,
      isError: !result.ok,
    );
  }

  Future<void> _openRequest() async {
    final meta = controller.meta.value;
    if (meta == null) return;
    final search = controller.search.value.trim();
    final chapter = int.tryParse(search);
    final outcome = await Get.to<LibraryRequestOutcome>(
          () => LibraryRequestViews(
        meta: meta,
        initialPublication: controller.publicationFilter.value,
        initialSubject: controller.subjectFilter.value,
        initialChapter: chapter,
        initialTitle: chapter == null ? search : '',
        onPublicationListed: controller.rememberPublication,
      ),
    );
    unawaited(controller.refreshAfterReturn());
    if (outcome == null) return;
    showLibrarySnack(outcome.message);
    final lesson = outcome.lesson;
    if (lesson == null) return;
    if (outcome.alreadyExists) {
      // Not an error: the chapter is there already — just open it.
      await _openLesson(lesson);
    } else if (controller.myRequests.loadedOnce) {
      unawaited(controller.myRequests.reload(silent: true));
    }
  }

  Future<void> _pickClass() async {
    await showClassChangeSheet(context);
    await controller.refreshAfterClassChange();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LibraryPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            LibraryTopBar(
              title: 'Library',
              trailing: Obx(
                    () => controller.hasClass
                    ? IconButton(
                  tooltip: 'Request a lesson',
                  onPressed: _openRequest,
                  icon: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: AppColors.primary,
                  ),
                )
                    : const SizedBox.shrink(),
              ),
            ),
            Expanded(
              child: Obx(() {
                final meta = controller.meta.value;
                if (controller.isLoadingMeta.value && meta == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (meta == null) {
                  final status = controller.metaErrorStatus.value;
                  return LibraryMessageView(
                    icon: status == 403
                        ? Icons.lock_outline_rounded
                        : Icons.cloud_off_rounded,
                    title: status == 403
                        ? 'Library is for students'
                        : 'Unable to open the Library',
                    message: controller.metaError.value,
                    actionLabel: status == 403 ? null : 'Retry',
                    onAction: status == 403 ? null : controller.loadAll,
                  );
                }
                if (meta.classLevel == null) {
                  return LibraryMessageView(
                    icon: Icons.school_outlined,
                    title: 'Choose your class first',
                    message:
                    'The Library shows lessons for your class. '
                        'Pick your class to see them.',
                    actionLabel: 'Choose class',
                    onAction: _pickClass,
                  );
                }
                return Column(
                  children: [
                    _LibraryHeader(meta: meta),
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabs,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textMuted,
                        indicatorColor: AppColors.primary,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                        tabs: const [
                          Tab(text: 'Browse'),
                          Tab(text: 'My requests'),
                          Tab(text: 'My uploads'),
                          Tab(text: 'Following'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabs,
                        children: [
                          _BrowseTab(
                            controller: controller,
                            rowBuilder: _row,
                            onRequest: _openRequest,
                          ),
                          _LessonListTab(
                            list: controller.myRequests,
                            rowBuilder: _row,
                            emptyIcon: Icons.post_add_rounded,
                            emptyTitle: 'No requests yet',
                            emptyMessage:
                            "Can't find a lesson from your book? "
                                'Request it and we will tell you when it is ready.',
                            emptyActionLabel: 'Request a lesson',
                            onEmptyAction: _openRequest,
                          ),
                          _LessonListTab(
                            list: controller.myUploads,
                            rowBuilder: _row,
                            emptyIcon: Icons.photo_library_outlined,
                            emptyTitle: 'No uploads yet',
                            emptyMessage:
                            'Lessons you photograph for other students '
                                'show up here.',
                          ),
                          _LessonListTab(
                            list: controller.following,
                            rowBuilder: _row,
                            emptyIcon: Icons.notifications_none_rounded,
                            emptyTitle: 'Not following anything',
                            emptyMessage:
                            'Follow a lesson that is not ready yet and we '
                                'will notify you when you can read it.',
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(LibraryLesson lesson) {
    return Obx(
          () => LibraryLessonCard(
        lesson: lesson,
        uploadsAvailable: controller.meta.value?.uploadsAvailable ?? true,
        followBusy: controller.busyIds.contains(lesson.id),
        onOpen: () => _openLesson(lesson),
        onRead: () => _openLesson(lesson),
        onUpload: () => _upload(lesson),
        onContinue: () => _continue(lesson),
        onToggleFollow: () => _toggleFollow(lesson),
      ),
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({required this.meta});

  final LibraryMeta meta;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lessons from other books · Class ${meta.classLevel}',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              LibraryQuotaPill(
                icon: Icons.post_add_rounded,
                label: 'Requests left',
                quota: meta.requests,
              ),
              if (meta.uploadsAvailable)
                LibraryQuotaPill(
                  icon: Icons.photo_camera_outlined,
                  label: 'Uploads left',
                  quota: meta.uploads,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

typedef _RowBuilder = Widget Function(LibraryLesson lesson);

class _BrowseTab extends StatefulWidget {
  const _BrowseTab({
    required this.controller,
    required this.rowBuilder,
    required this.onRequest,
  });

  final LibraryController controller;
  final _RowBuilder rowBuilder;
  final VoidCallback onRequest;

  @override
  State<_BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends State<_BrowseTab>
    with AutomaticKeepAliveClientMixin {
  late final TextEditingController _search = TextEditingController(
    text: widget.controller.search.value,
  );

  LibraryController get c => widget.controller;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _pickPublication() async {
    final meta = c.meta.value;
    if (meta == null) return;
    final picked = await _showRefPicker(
      context,
      title: 'Publication',
      options: meta.publications,
      selected: c.publicationFilter.value,
      searchable: true,
    );
    if (picked == null) return;
    c.setPublication(picked.id.isEmpty ? null : picked);
  }

  Future<void> _pickSubject() async {
    final meta = c.meta.value;
    if (meta == null) return;
    final picked = await _showRefPicker(
      context,
      title: 'Subject',
      options: meta.subjects,
      selected: c.subjectFilter.value,
    );
    if (picked == null) return;
    c.setSubject(picked.id.isEmpty ? null : picked);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final list = c.browse;
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            children: [
              TextField(
                controller: _search,
                onChanged: c.onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search by lesson name or chapter no.',
                  hintStyle: const TextStyle(
                    color: AppColors.textMuted6,
                    fontSize: 13.5,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, size: 21),
                  suffixIcon: Obx(
                        () => c.search.value.isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 19),
                      onPressed: () {
                        _search.clear();
                        c.onSearchChanged('');
                      },
                    ),
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.neutralSurface2,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                child: Obx(
                      () => ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChipButton(
                        label: c.publicationFilter.value?.name ?? 'Publication',
                        active: c.publicationFilter.value != null,
                        onTap: _pickPublication,
                      ),
                      const SizedBox(width: 8),
                      _FilterChipButton(
                        label: c.subjectFilter.value?.name ?? 'Subject',
                        active: c.subjectFilter.value != null,
                        onTap: _pickSubject,
                      ),
                      const SizedBox(width: 8),
                      for (final s in LibraryStatusFilter.values) ...[
                        ChoiceChip(
                          label: Text(s.label),
                          selected: c.statusFilter.value == s,
                          onSelected: (_) => c.setStatus(s),
                          labelStyle: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: c.statusFilter.value == s
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          selectedColor: AppColors.primaryPale,
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: c.statusFilter.value == s
                                ? AppColors.primary.withValues(alpha: 0.4)
                                : LibraryPalette.border,
                          ),
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (list.isLoading.value && list.items.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (list.error.value.isNotEmpty && list.items.isEmpty) {
              return LibraryMessageView(
                icon: Icons.cloud_off_rounded,
                title: 'Unable to load lessons',
                message: list.error.value,
                actionLabel: 'Retry',
                onAction: list.reload,
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                await c.loadMeta(silent: true);
                await list.reload(silent: true);
              },
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.pixels > n.metrics.maxScrollExtent - 300) {
                    list.loadMore();
                  }
                  return false;
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
                  itemCount: list.items.length + 1,
                  itemBuilder: (context, index) {
                    if (index < list.items.length) {
                      return widget.rowBuilder(list.items[index]);
                    }
                    return Obx(
                          () => _BrowseFooter(
                        loadingMore: list.isLoadingMore.value,
                        isEmpty: list.items.isEmpty,
                        filtered: c.hasActiveFilters,
                        onClearFilters: () {
                          _search.clear();
                          c.clearFilters();
                        },
                        onRequest: widget.onRequest,
                      ),
                    );
                  },
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BrowseFooter extends StatelessWidget {
  const _BrowseFooter({
    required this.loadingMore,
    required this.isEmpty,
    required this.filtered,
    required this.onClearFilters,
    required this.onRequest,
  });

  final bool loadingMore;
  final bool isEmpty;
  final bool filtered;
  final VoidCallback onClearFilters;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    if (loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      );
    }
    return Column(
      children: [
        if (isEmpty) ...[
          const SizedBox(height: 40),
          const Icon(
            Icons.local_library_outlined,
            color: Color(0xFF9AA0B0),
            size: 54,
          ),
          const SizedBox(height: 14),
          Text(
            filtered ? 'No lessons match' : 'The Library is empty for now',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Be the first to ask for a lesson from your book.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          if (filtered)
            TextButton(
              onPressed: onClearFilters,
              child: const Text('Clear filters'),
            ),
          const SizedBox(height: 10),
        ],
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            color: AppColors.primaryPale,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(Icons.help_outline_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Can't find your lesson?",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              LibraryPrimaryButton(label: 'Request it', onPressed: onRequest),
            ],
          ),
        ),
      ],
    );
  }
}

class _LessonListTab extends StatefulWidget {
  const _LessonListTab({
    required this.list,
    required this.rowBuilder,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyMessage,
    this.emptyActionLabel,
    this.onEmptyAction,
  });

  final LibraryLessonList list;
  final _RowBuilder rowBuilder;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;

  @override
  State<_LessonListTab> createState() => _LessonListTabState();
}

class _LessonListTabState extends State<_LessonListTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final list = widget.list;
    return Obx(() {
      if ((list.isLoading.value || !list.loadedOnce) && list.items.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (list.error.value.isNotEmpty && list.items.isEmpty) {
        return LibraryMessageView(
          icon: Icons.cloud_off_rounded,
          title: 'Unable to load',
          message: list.error.value,
          actionLabel: 'Retry',
          onAction: list.reload,
        );
      }
      if (list.items.isEmpty) {
        return RefreshIndicator(
          onRefresh: () => list.reload(silent: true),
          child: LibraryMessageView(
            icon: widget.emptyIcon,
            title: widget.emptyTitle,
            message: widget.emptyMessage,
            actionLabel: widget.emptyActionLabel,
            onAction: widget.onEmptyAction,
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: () => list.reload(silent: true),
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.pixels > n.metrics.maxScrollExtent - 300) {
              list.loadMore();
            }
            return false;
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
            itemCount: list.items.length + (list.isLoadingMore.value ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= list.items.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                );
              }
              return widget.rowBuilder(list.items[index]);
            },
          ),
        ),
      );
    });
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.primaryPale : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active
                ? AppColors.primary.withValues(alpha: 0.4)
                : LibraryPalette.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? AppColors.primary : AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: active ? AppColors.primary : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom-sheet picker for a publication or subject. Returns
/// [LibraryRef.empty] for "All", `null` when dismissed.
Future<LibraryRef?> _showRefPicker(
    BuildContext context, {
      required String title,
      required List<LibraryRef> options,
      required LibraryRef? selected,
      bool searchable = false,
    }) {
  return showModalBottomSheet<LibraryRef>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _RefPickerSheet(
      title: title,
      options: options,
      selected: selected,
      searchable: searchable,
    ),
  );
}

class _RefPickerSheet extends StatefulWidget {
  const _RefPickerSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.searchable,
  });

  final String title;
  final List<LibraryRef> options;
  final LibraryRef? selected;
  final bool searchable;

  @override
  State<_RefPickerSheet> createState() => _RefPickerSheetState();
}

class _RefPickerSheetState extends State<_RefPickerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.options
        .where((o) => o.name.toLowerCase().contains(_q.toLowerCase()))
        .toList();
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD5D9E4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (widget.searchable)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    onChanged: (v) => setState(() => _q = v.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
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
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (_q.isEmpty)
                      _PickerTile(
                        label: 'All',
                        selected: widget.selected == null,
                        onTap: () =>
                            Navigator.of(context).pop(LibraryRef.empty),
                      ),
                    for (final o in filtered)
                      _PickerTile(
                        label: o.name,
                        selected: widget.selected?.id == o.id,
                        onTap: () => Navigator.of(context).pop(o),
                      ),
                    if (filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Nothing found',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted),
                        ),
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

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          color: selected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_rounded, color: AppColors.primary)
          : null,
    );
  }
}
import 'dart:async';

import 'package:get/get.dart';

import '../../../core/service/api_service.dart';
import '../data/library_models.dart';
import '../data/library_repository.dart';

typedef LibraryPageFetcher =
    Future<LibraryResult<LibraryLessonPage>> Function(int page, int limit);

/// One paged list of lesson rows (Browse, My requests, My uploads, Following).
class LibraryLessonList {
  LibraryLessonList(this._fetch);

  final LibraryPageFetcher _fetch;

  static const int _limit = 20;

  final RxList<LibraryLesson> items = <LibraryLesson>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString error = ''.obs;
  final RxInt errorStatus = 0.obs;
  final RxInt total = 0.obs;
  bool loadedOnce = false;

  int _page = 1;
  int _totalPages = 1;

  /// Bumped on every reload so a slow, older answer never overwrites a newer
  /// one (e.g. while the student is typing in search).
  int _generation = 0;

  bool get hasMore => _page < _totalPages;

  Future<void> reload({bool silent = false}) async {
    final generation = ++_generation;
    if (!silent || items.isEmpty) isLoading.value = true;
    error.value = '';
    final result = await _fetch(1, _limit);
    if (generation != _generation) return;
    isLoading.value = false;
    loadedOnce = true;
    if (!result.ok || result.data == null) {
      errorStatus.value = result.statusCode;
      if (!silent || items.isEmpty) {
        items.clear();
        error.value = result.displayMessage;
      }
      return;
    }
    errorStatus.value = 0;
    final page = result.data!;
    _page = 1;
    _totalPages = page.pagination.totalPages;
    total.value = page.pagination.total;
    items.assignAll(page.lessons);
  }

  Future<void> loadMore() async {
    if (!hasMore || isLoading.value || isLoadingMore.value) return;
    final generation = _generation;
    isLoadingMore.value = true;
    final result = await _fetch(_page + 1, _limit);
    if (generation != _generation) return;
    isLoadingMore.value = false;
    if (!result.ok || result.data == null) return;
    final page = result.data!;
    _page = page.pagination.page;
    _totalPages = page.pagination.totalPages;
    final known = items.map((e) => e.id).toSet();
    items.addAll(page.lessons.where((e) => !known.contains(e.id)));
  }

  /// Puts a fresher copy of a lesson in place, wherever it is in the list.
  void replace(LibraryLesson lesson) {
    final index = items.indexWhere((e) => e.id == lesson.id);
    if (index >= 0) items[index] = lesson;
  }
}

/// Filter on publication status in Browse.
enum LibraryStatusFilter {
  all(null, 'Everything'),
  available('available', 'Ready to read'),
  pending('pending', 'Coming soon');

  const LibraryStatusFilter(this.apiValue, this.label);

  final String? apiValue;
  final String label;
}

/// Library home: meta (subjects, publications, today's limits), the Browse
/// catalogue of the student's class, and the student's own lists.
class LibraryController extends GetxController {
  final Rxn<LibraryMeta> meta = Rxn<LibraryMeta>();
  final RxBool isLoadingMeta = true.obs;
  final RxString metaError = ''.obs;
  final RxInt metaErrorStatus = 0.obs;

  final Rxn<LibraryRef> publicationFilter = Rxn<LibraryRef>();
  final Rxn<LibraryRef> subjectFilter = Rxn<LibraryRef>();
  final Rx<LibraryStatusFilter> statusFilter = LibraryStatusFilter.all.obs;
  final RxString search = ''.obs;

  /// Lesson ids with a follow / unfollow call in flight.
  final RxSet<String> busyIds = <String>{}.obs;

  late final LibraryLessonList browse = LibraryLessonList(
    (page, limit) => LibraryRepository.fetchLessons(
      publicationId: publicationFilter.value?.id,
      subjectId: subjectFilter.value?.id,
      status: statusFilter.value.apiValue,
      query: search.value,
      page: page,
      limit: limit,
    ),
  );

  late final LibraryLessonList myRequests = LibraryLessonList(
    (page, limit) => LibraryRepository.fetchMyList(
      ApiService.LIBRARY_MY_REQUESTS,
      page: page,
      limit: limit,
    ),
  );

  late final LibraryLessonList myUploads = LibraryLessonList(
    (page, limit) => LibraryRepository.fetchMyList(
      ApiService.LIBRARY_MY_UPLOADS,
      page: page,
      limit: limit,
    ),
  );

  late final LibraryLessonList following = LibraryLessonList(
    (page, limit) => LibraryRepository.fetchMyList(
      ApiService.LIBRARY_MY_FOLLOWING,
      page: page,
      limit: limit,
    ),
  );

  List<LibraryLessonList> get _allLists => [
    browse,
    myRequests,
    myUploads,
    following,
  ];

  Timer? _searchDebounce;

  bool get hasClass => meta.value?.classLevel != null;

  bool get hasActiveFilters =>
      publicationFilter.value != null ||
      subjectFilter.value != null ||
      statusFilter.value != LibraryStatusFilter.all ||
      search.value.trim().isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
  }

  Future<void> loadAll() async {
    await loadMeta();
    if (hasClass) {
      await browse.reload();
    }
  }

  Future<void> loadMeta({bool silent = false}) async {
    if (!silent || meta.value == null) isLoadingMeta.value = true;
    final result = await LibraryRepository.fetchMeta();
    isLoadingMeta.value = false;
    if (!result.ok || result.data == null) {
      metaErrorStatus.value = result.statusCode;
      if (!silent || meta.value == null) {
        metaError.value = result.displayMessage;
      }
      return;
    }
    metaError.value = '';
    metaErrorStatus.value = 0;
    meta.value = result.data;

    // A filter pointing at something no longer offered would hide everything.
    final m = result.data!;
    if (publicationFilter.value != null &&
        !m.publications.contains(publicationFilter.value)) {
      publicationFilter.value = null;
    }
    if (subjectFilter.value != null &&
        !m.subjects.contains(subjectFilter.value)) {
      subjectFilter.value = null;
    }
  }

  /// After the student comes back from a lesson / upload / request: limits and
  /// every row's `myState` may have changed in the meantime.
  Future<void> refreshAfterReturn() async {
    await loadMeta(silent: true);
    for (final list in _allLists) {
      if (list.loadedOnce) unawaited(list.reload(silent: true));
    }
  }

  /// The Library follows the current class, so a class change reloads it all.
  Future<void> refreshAfterClassChange() async {
    publicationFilter.value = null;
    subjectFilter.value = null;
    await loadMeta();
    if (hasClass) await browse.reload();
    for (final list in [myRequests, myUploads, following]) {
      if (list.loadedOnce) unawaited(list.reload(silent: true));
    }
  }

  void setPublication(LibraryRef? value) {
    publicationFilter.value = value;
    browse.reload();
  }

  void setSubject(LibraryRef? value) {
    subjectFilter.value = value;
    browse.reload();
  }

  void setStatus(LibraryStatusFilter value) {
    if (statusFilter.value == value) return;
    statusFilter.value = value;
    browse.reload();
  }

  /// Sets the status filter without refetching — for a screen that is about
  /// to load the list anyway.
  void setStatusSilently(LibraryStatusFilter value) {
    statusFilter.value = value;
  }

  void onSearchChanged(String value) {
    search.value = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 400),
      () => browse.reload(),
    );
  }

  void clearFilters() {
    publicationFilter.value = null;
    subjectFilter.value = null;
    statusFilter.value = LibraryStatusFilter.all;
    search.value = '';
    browse.reload();
  }

  /// Adds a newly listed publication (e.g. from a `409` "already listed").
  void rememberPublication(LibraryRef publication) {
    final m = meta.value;
    if (m == null || publication.id.isEmpty) return;
    if (m.publications.contains(publication)) return;
    meta.value = LibraryMeta(
      classLevel: m.classLevel,
      subjects: m.subjects,
      publications: [...m.publications, publication]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
      requests: m.requests,
      uploads: m.uploads,
      rules: m.rules,
      uploadsAvailable: m.uploadsAvailable,
    );
  }

  /// Applies a fresher copy of [lesson] to every list showing it.
  void applyLesson(LibraryLesson lesson) {
    for (final list in _allLists) {
      list.replace(lesson);
    }
  }

  /// Follow / unfollow from a row. Returns the server's message.
  Future<LibraryResult<LibraryLesson?>> toggleFollow(
    LibraryLesson lesson,
  ) async {
    busyIds.add(lesson.id);
    final wantFollow = !lesson.isFollowing;
    final result = wantFollow
        ? await LibraryRepository.follow(lesson.id)
        : await LibraryRepository.unfollow(lesson.id);
    busyIds.remove(lesson.id);

    if (result.ok) {
      applyLesson(result.data ?? lesson.withFollowing(wantFollow));
      if (!wantFollow && following.loadedOnce) {
        following.items.removeWhere((e) => e.id == lesson.id);
      } else if (following.loadedOnce) {
        unawaited(following.reload(silent: true));
      }
    } else if (result.statusCode == 409 || result.statusCode == 404) {
      // The lesson moved on (published, removed…): show its real state.
      final fresh = await LibraryRepository.fetchLesson(lesson.id);
      if (fresh.ok && fresh.data != null) applyLesson(fresh.data!);
    }
    return result;
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../../core/data/user_profile_provider.dart';
import '../../../../core/service/learn_progress_refresh_service.dart';
import '../controller/learn_chapter_controller.dart';
import 'learn_chapter_views.dart';

class LearnSubjectViews extends StatefulWidget {
  const LearnSubjectViews({super.key});

  @override
  State<LearnSubjectViews> createState() => _LearnSubjectViewsState();
}

class _LearnSubjectViewsState extends State<LearnSubjectViews> {
  String _query = '';
  bool _isLoading = true;
  String _errorMessage = '';
  List<LearnSubjectModel> _subjects = const [];
  List<LearnPublicationSubjectGroup> _publicationGroups = const [];
  late final Worker _refreshWorker;

  @override
  void initState() {
    super.initState();
    _refreshWorker = ever<int>(
      LearnProgressRefreshService.instance.refreshTick,
      (_) {
        if (mounted) {
          _loadSubjects();
        }
      },
    );
    _loadSubjects();
  }

  @override
  void dispose() {
    _refreshWorker.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final publicationFuture = LearnCatalogData.getLibraryPublicationSubjects();
    final subjectFuture = LearnCatalogData.getUserSubjects();
    final publicationResponse = await publicationFuture;
    final subjectResponse = await subjectFuture;

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _publicationGroups = publicationResponse.data ?? const [];
      _subjects = subjectResponse.data ?? const [];
      _errorMessage = subjectResponse.success ? '' : subjectResponse.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserProfileProvider>().profile;
    final gradeLabel = _subjects.isNotEmpty
        ? _subjects.first.classLevel
        : (profile?.userClass ?? '-');
    final query = _query.trim().toLowerCase();
    final subjects = _subjects.where((subject) {
      if (query.isEmpty) {
        return true;
      }
      return subject.title.toLowerCase().contains(query) ||
          subject.subtitle.toLowerCase().contains(query);
    }).toList();
    final publicationGroups = _publicationGroups
        .map((group) {
          final filteredSubjects = group.subjects.where((subject) {
            if (query.isEmpty) return true;
            return group.publicationName.toLowerCase().contains(query) ||
                subject.title.toLowerCase().contains(query) ||
                subject.subtitle.toLowerCase().contains(query);
          }).toList();
          return LearnPublicationSubjectGroup(
            publicationId: group.publicationId,
            publicationName: group.publicationName,
            subjects: filteredSubjects,
          );
        })
        .where((group) => group.subjects.isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFEFF1FA),
      body: SafeArea(
        child: Column(
          children: [
            const LearnTopBar(title: 'Subject'),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadSubjects,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                  children: [
                    const _SubjectSectionTitle(title: 'Select a Subject'),
                    const SizedBox(height: 6),
                    Text(
                      'Grade $gradeLabel',
                      style: const TextStyle(
                        color: Color(0xFF4F5367),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ClaySurface(
                      radius: 18,
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _query = value;
                          });
                        },
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search your subjects...',
                          hintStyle: TextStyle(
                            color: Color(0xFF8A8FA6),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: Color(0xFF7D8092),
                            size: 22,
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_errorMessage.isNotEmpty)
                      _ErrorStateCard(
                        message: _errorMessage,
                        onRetry: _loadSubjects,
                      )
                    else if (subjects.isEmpty && publicationGroups.isEmpty)
                      const _EmptyStateCard(
                        title: 'No subjects found',
                        message: 'Try a different search or pull to refresh.',
                      )
                    else ...[
                      if (publicationGroups.isNotEmpty) ...[
                        const _SubjectSectionTitle(title: 'Other Publications'),
                        const SizedBox(height: 12),
                        for (final group in publicationGroups) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _PublicationSectionLabel(
                              title: group.publicationName,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _SubjectGrid(
                            subjects: group.subjects,
                            onReload: _loadSubjects,
                          ),
                          const SizedBox(height: 18),
                        ],
                      ],
                      if (subjects.isNotEmpty) ...[
                        const _SubjectSectionTitle(title: 'My Subjects'),
                        const SizedBox(height: 12),
                        _SubjectGrid(
                          subjects: subjects,
                          onReload: _loadSubjects,
                        ),
                      ],
                    ],
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

class _SubjectSectionTitle extends StatelessWidget {
  const _SubjectSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF1D2231),
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _PublicationSectionLabel extends StatelessWidget {
  const _PublicationSectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return _ClaySurface(
      radius: 14,
      color: const Color(0xFFF4F5FC),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF4F5367),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class LearnTopBar extends StatelessWidget {
  const LearnTopBar({super.key, required this.title, this.trailing});

  final String title;

  /// Optional trailing action (e.g. a search icon). Kept the same width as the
  /// leading back button so the title stays centered.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE7EAF4))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF103383),
              size: 22,
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF103383),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: trailing == null ? null : Center(child: trailing),
          ),
        ],
      ),
    );
  }
}

/// Soft claymorphic surface: a puffy, rounded shape with a dark outer shadow
/// for lift plus a white inner highlight so it reads as moulded clay.
class _ClaySurface extends StatelessWidget {
  const _ClaySurface({
    required this.child,
    this.color = const Color(0xFFFFFFFF),
    this.radius = 24,
    this.shadowColor = const Color(0xFFB9BEDB),
  });

  final Widget child;
  final Color color;
  final double radius;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          // Outer lift.
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(6, 8),
          ),
          // Top-left light source.
          const BoxShadow(
            color: Color(0xFFFFFFFF),
            blurRadius: 14,
            offset: Offset(-5, -5),
          ),
          // Inner highlight rim.
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.9),
            blurRadius: 4,
            offset: const Offset(-2, -2),
            spreadRadius: -2,
            blurStyle: BlurStyle.inner,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Two-column grid of compact subject tiles.
class _SubjectGrid extends StatelessWidget {
  const _SubjectGrid({required this.subjects, required this.onReload});

  final List<LearnSubjectModel> subjects;
  final Future<void> Function() onReload;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: subjects.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 16,
        mainAxisExtent: 168,
      ),
      itemBuilder: (context, index) =>
          _SubjectDetailsCard(subject: subjects[index], onReload: onReload),
    );
  }
}

class _SubjectDetailsCard extends StatelessWidget {
  const _SubjectDetailsCard({required this.subject, required this.onReload});

  final LearnSubjectModel subject;
  final Future<void> Function() onReload;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final shouldReload = await Get.to<bool>(
          () => LearnChapterViews(subject: subject),
        );
        if (shouldReload == true) {
          await onReload();
        }
      },
      borderRadius: BorderRadius.circular(24),
      child: _ClaySurface(
        shadowColor: subject.accent,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ClaySurface(
                    color: subject.iconBackground,
                    radius: 16,
                    shadowColor: subject.accent,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        subject.icon,
                        color: subject.accent,
                        size: 22,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (subject.statusLabel != null)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: subject.accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          subject.statusLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: subject.accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                subject.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF1D2231),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subject.subtitle.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  subject.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B7089),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      subject.progressText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF3F4358),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    subject.progressPercentage,
                    style: TextStyle(
                      color: subject.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: subject.progress,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE4E7EE),
                  valueColor: AlwaysStoppedAnimation<Color>(subject.accent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorStateCard extends StatelessWidget {
  const _ErrorStateCard({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return _ClaySurface(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unable to load subjects',
              style: TextStyle(
                color: Color(0xFF1D2231),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(
                color: Color(0xFF4F5367),
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A4FD9),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _ClaySurface(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF1D2231),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(
                color: Color(0xFF4F5367),
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

    final response = await LearnCatalogData.getUserSubjects();

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _subjects = response.data ?? const [];
      _errorMessage = response.success ? '' : response.message;
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

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      body: SafeArea(
        child: Column(
          children: [
            const LearnTopBar(title: 'Subject'),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadSubjects,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
                  children: [
                    const Text(
                      'Select a Subject',
                      style: TextStyle(
                        color: Color(0xFF1D2231),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Grade $gradeLabel',
                      style: const TextStyle(
                        color: Color(0xFF4F5367),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      onChanged: (value) {
                        setState(() {
                          _query = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search your subjects...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF72788D),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF7D8092),
                          size: 22,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFC7C3F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFC7C3F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF4A4FD9),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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
                    else if (subjects.isEmpty)
                      const _EmptyStateCard(
                        title: 'No subjects found',
                        message: 'Try a different search or pull to refresh.',
                      )
                    else
                      ...subjects.map(
                        (subject) => Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: _SubjectDetailsCard(
                            subject: subject,
                            onReload: _loadSubjects,
                          ),
                        ),
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

class _SubjectDetailsCard extends StatelessWidget {
  const _SubjectDetailsCard({
    required this.subject,
    required this.onReload,
  });

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
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFC8C7F1)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD6DCEF).withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: subject.iconBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(subject.icon, color: subject.accent, size: 30),
                ),
                const Spacer(),
                if (subject.statusLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: subject.accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      subject.statusLabel!,
                      style: TextStyle(
                        color: subject.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              subject.title,
              style: const TextStyle(
                color: Color(0xFF1D2231),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subject.subtitle,
              style: const TextStyle(
                color: Color(0xFF4F5367),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: Text(
                    subject.progressText,
                    style: const TextStyle(
                      color: Color(0xFF3F4358),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  subject.progressPercentage,
                  style: TextStyle(
                    color: subject.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: subject.progress,
                minHeight: 8,
                backgroundColor: const Color(0xFFE4E7EE),
                valueColor: AlwaysStoppedAnimation<Color>(subject.accent),
              ),
            ),
          ],
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC8C7F1)),
      ),
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
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC8C7F1)),
      ),
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
    );
  }
}

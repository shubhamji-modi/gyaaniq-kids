import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/data/user_profile_provider.dart';
import '../../../../core/service/api_service.dart';
import '../../../../routes/app_routes.dart';
import '../../../../core/service/app_features_service.dart';
import '../../../../core/service/app_route_observer.dart';
import '../../../../core/service/app_update_service.dart';
import '../../../../core/service/device_token_service.dart';
import '../../../../core/service/learn_progress_refresh_service.dart';
import '../../../../core/service/notification_badge_service.dart';
import '../../../../core/service/notification_service.dart';
import '../../../../core/theme/appcolors.dart';
import '../../../../core/widgets/app_feature_gate.dart';
import '../../notifications/controller/notification_controller.dart';

import '../../menubar/edit profile/views/edit_profile_views.dart';
import '../../menubar/query/controller/user_query_controller.dart';
import '../../daily_quiz/views/start_quiz_views.dart';
import '../../daily_quiz/result/preview_result/controller/preview_result_controller.dart';
import '../../daily_quiz/result/preview_result/views/preview_result_views.dart';
import '../../daily_quiz/practice_test/Views/quiz_practice_paper_subject_views.dart';
import '../../fun_fact/controller/fun_fact_controller.dart';
import '../../fun_fact/fun_fact_image.dart';
import '../../fun_fact/views/fun_fact_story_views.dart';
import '../../subscription/subscription_views.dart';
import '../controllers/dashboard_tabbar_controller.dart';
import 'daily_rewards_views.dart';
import 'performance_dna_views.dart';

String _profileFirstName(String? name) {
  final trimmedName = name?.trim() ?? '';
  if (trimmedName.isEmpty) {
    return 'Student';
  }

  return trimmedName.split(RegExp(r'\s+')).first;
}

String _educationBoardLabel(String? board) {
  final trimmedBoard = board?.trim() ?? '';
  if (trimmedBoard.isEmpty || trimmedBoard == '-') {
    return '-';
  }
  if (RegExp(r'\s+board$', caseSensitive: false).hasMatch(trimmedBoard)) {
    return trimmedBoard;
  }
  return '$trimmedBoard Board';
}

DashboardTabbarController _dashboardController() {
  try {
    return Get.find<DashboardTabbarController>();
  } catch (_) {
    return Get.put(DashboardTabbarController());
  }
}

class DashboardTabbarViewsScreen extends StatefulWidget {
  const DashboardTabbarViewsScreen({super.key});

  @override
  State<DashboardTabbarViewsScreen> createState() =>
      _DashboardTabbarViewsScreenState();
}

class _DashboardTabbarViewsScreenState extends State<DashboardTabbarViewsScreen>
    with RouteAware {
  bool _isFetchingProfile = false;
  bool _hasHandledLaunchArgs = false;
  bool _isRouteObserverSubscribed = false;
  late final Worker _refreshWorker;

  @override
  void initState() {
    super.initState();
    _refreshWorker = ever<int>(
      LearnProgressRefreshService.instance.refreshTick,
      (_) {
        if (!mounted) {
          return;
        }
        _dashboardController().loadDashboardData(force: true);
        _fetchProfile();
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleLaunchArgs();
      _reloadHomeTabApis();
      _fetchProfile();
      _sendDeviceToken();
      AppUpdateService.instance.checkForUpdate();
      // Navigation is safe from here on: a push tapped while the app was
      // killed has been waiting for this and now opens on the Notifications
      // screen rather than over the splash or whichever tab is showing.
      NotificationController.markAppReady();
    });
  }

  void _sendDeviceToken() {
    DeviceTokenService.instance.sendToken(
      NotificationService.instance.currentToken,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isRouteObserverSubscribed) {
      return;
    }

    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
      _isRouteObserverSubscribed = true;
    }
  }

  @override
  void dispose() {
    if (_isRouteObserverSubscribed) {
      appRouteObserver.unsubscribe(this);
    }
    _refreshWorker.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    _reloadHomeTabApis();
    _fetchProfile();
    _sendDeviceToken();
  }

  void _reloadHomeTabApis() {
    if (!mounted) {
      return;
    }

    final controller = _dashboardController();
    if (controller.currentTabIndex.value == 0) {
      controller.reloadHomeTabData();
      // Returning from a quiz/lesson can change the weak areas, so they are
      // always refetched rather than served from the TTL cache.
      controller.loadWeakAreas(force: true);
    } else if (controller.currentTabIndex.value == 2) {
      controller.reloadQuizTabData();
    }
  }

  void _handleLaunchArgs() {
    if (_hasHandledLaunchArgs || !mounted) {
      return;
    }
    _hasHandledLaunchArgs = true;

    final controller = _dashboardController();
    final args = Get.arguments;
    if (args is! Map) {
      return;
    }

    final initialTab = args['initialTab'];
    if (initialTab is int) {
      controller.changeTab(initialTab);
    }

    if (args['forceReload'] == true) {
      controller.loadDashboardData();
      _fetchProfile();
    }

    final successMessage = args['successMessage']?.toString().trim() ?? '';
    if (successMessage.isNotEmpty) {
      Future<void>.delayed(const Duration(milliseconds: 250), () {
        if (!mounted) {
          return;
        }
        Get.snackbar(
          'Success',
          successMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.white,
          colorText: const Color(0xFF1D2231),
          margin: const EdgeInsets.all(14),
        );
      });
    }
  }

  Future<void> _fetchProfile() async {
    if (_isFetchingProfile || !mounted) {
      return;
    }

    _isFetchingProfile = true;
    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.GET_PROFILE,
      showLoader: false,
      fromJson: (json) => json,
    );

    if (!mounted) {
      return;
    }

    _isFetchingProfile = false;

    if (!response.success || response.data is! Map<String, dynamic>) {
      return;
    }

    final body = response.data as Map<String, dynamic>;
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      return;
    }

    context.read<UserProfileProvider>().setProfile(UserProfile.fromApi(data));

    final mobile =
        data['phoneNumber']?.toString().trim() ??
        data['phone']?.toString().trim() ??
        '';
    if (mobile.isEmpty) {
      Get.offAllNamed(AppRoutes.phoneVerification);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _dashboardController();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        // Not on Home → go to Home first.
        if (controller.currentTabIndex.value != 0) {
          controller.changeTab(0);
          return;
        }
        // On Home → confirm before exiting the app.
        final shouldExit = await _showExitDialog(context);
        if (shouldExit) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        body: Obx(
          () => IndexedStack(
            index: controller.currentTabIndex.value,
            children: const [
              _HomeTab(),
              _LearnTab(),
              _QuizTab(),
              Offstage(offstage: true, child: _LiveTab()),
              _ProfileTab(),
            ],
          ),
        ),
        bottomNavigationBar: const _BottomNavBar(),
      ),
    );
  }

  Future<bool> _showExitDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Exit App',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          'Are you sure you want to exit the app?',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Exit',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _BottomNavBar extends GetView<DashboardTabbarController> {
  const _BottomNavBar();

  static const List<int> _visibleTabIndexes = [0, 1, 2, 4];

  // ---------------------------------------------------------------------------
  // Palette — the app's original bottom-bar colours.
  // ---------------------------------------------------------------------------
  /// Bar background.
  static const Color _barColor = AppColors.white;

  /// Subtle rim around the bar.
  static const Color _barBorder = Color(0xFFE7EAF4);

  /// Active tab accent (filled pill).
  static const Color _accent = AppColors.primaryBright;

  /// Icon + label colour on the active accent pill.
  static const Color _onAccent = AppColors.white;

  /// Idle icons.
  static const Color _inactive = AppColors.navUnselected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: _barColor,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: _barBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryShadow.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Obx(
          () => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final tabIndex in _visibleTabIndexes)
                _NavPill(
                  item: controller.navItems[tabIndex],
                  selected: controller.currentTabIndex.value == tabIndex,
                  accent: _accent,
                  onAccent: _onAccent,
                  inactive: _inactive,
                  onTap: () => controller.changeTab(tabIndex),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One tab: an icon that expands into an accent pill with its label when
/// selected, and collapses back to a bare icon when not.
class _NavPill extends StatelessWidget {
  const _NavPill({
    required this.item,
    required this.selected,
    required this.accent,
    required this.onAccent,
    required this.inactive,
    required this.onTap,
  });

  final DashboardNavItemData item;
  final bool selected;
  final Color accent;
  final Color onAccent;
  final Color inactive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 18 : 13,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: selected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 22, color: selected ? onAccent : inactive),
            // The label only exists for the selected tab; AnimatedSize slides
            // the pill open/closed as selection moves.
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          color: onAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fires once the dashboard header's name/board/class intro animation
/// finishes, so other widgets (progress bars, leaderboard avatars) can
/// start their own entrance animations right after.
final ValueNotifier<bool> _headerIntroDone = ValueNotifier<bool>(false);

class _DashboardScaffold extends StatelessWidget {
  const _DashboardScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    _headerIntroDone.value = false;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const _DashboardHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHeader extends GetView<DashboardTabbarController> {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<UserProfileProvider>(context).profile;
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.headerBorder)),
      ),
      child: Row(
        children: [
          _ProfileAvatar(
            imageUrl: profile?.profilePic ?? '',
            size: 46,
            iconSize: 30,
            borderWidth: 2,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _AnimatedHeaderInfo(
              name: _profileFirstName(profile?.name),
              boardLabel: _educationBoardLabel(profile?.educationBoard),
              classLabel: 'Class ${profile?.userClass ?? '-'}',
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0E0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: Color(0xFFFF7A00),
                  size: 22,
                ),
                const SizedBox(width: 7),
                Obx(
                  () => Text(
                    '${controller.userXpSummary.value.streakCount}',
                    style: const TextStyle(
                      color: Color(0xFF1F2433),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _NotificationBell(),
        ],
      ),
    );
  }
}

/// Staged header intro animation:
/// 1. Only the student's name is shown, centered.
/// 2. After 1s, the name slides up and sticks to the top while the
///    education board slides up into view below it.
/// 3. After another 1s, the board label slides out/up and is replaced by
///    the class label (which stays put afterwards).
class _AnimatedHeaderInfo extends StatefulWidget {
  const _AnimatedHeaderInfo({
    required this.name,
    required this.boardLabel,
    required this.classLabel,
  });

  final String name;
  final String boardLabel;

  /// Shown, never tappable. Changing class is deliberate and one-way, so it
  /// lives behind the Profile tab's "Change Class" entry rather than a label
  /// sitting next to the student's name.
  final String classLabel;

  @override
  State<_AnimatedHeaderInfo> createState() => _AnimatedHeaderInfoState();
}

enum _HeaderStage { name, board, klass }

class _AnimatedHeaderInfoState extends State<_AnimatedHeaderInfo>
    with SingleTickerProviderStateMixin {
  _HeaderStage _stage = _HeaderStage.name;
  late final AnimationController _subLineController;

  static const _subLineHeight = 19.0;
  static const _transitionDuration = Duration(milliseconds: 450);

  @override
  void initState() {
    super.initState();
    _subLineController = AnimationController(
      vsync: this,
      duration: _transitionDuration,
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _stage = _HeaderStage.board);
      _subLineController.forward();
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        _subLineController.reverse().whenComplete(() {
          if (!mounted) return;
          setState(() => _stage = _HeaderStage.klass);
          _subLineController.forward().whenComplete(() {
            if (!mounted) return;
            _headerIntroDone.value = true;
          });
        });
      });
    });
  }

  @override
  void dispose() {
    _subLineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedAlign(
          duration: _transitionDuration,
          curve: Curves.easeOutCubic,
          alignment: Alignment.centerLeft,
          child: Text(
            widget.name,
            style: const TextStyle(
              color: AppColors.textPrimaryDeep,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _subLineController,
          builder: (context, _) {
            final t = Curves.easeOutCubic.transform(_subLineController.value);
            return ClipRect(
              child: Align(
                alignment: Alignment.topLeft,
                heightFactor: t,
                child: Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, (1 - t) * 10),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: SizedBox(
                        height: _subLineHeight,
                        child: Text(
                          _stage == _HeaderStage.board
                              ? widget.boardLabel
                              : widget.classLabel,
                          style: const TextStyle(
                            color: AppColors.textMuted2,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // Named route: a push tapped later needs to be able to tell whether the
      // Notifications screen is already open.
      onTap: () => Get.toNamed(AppRoutes.notifications),
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.neutralSurface2,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.textPrimaryDeep,
                size: 22,
              ),
            ),
            Positioned(
              top: -2,
              right: -2,
              child: ValueListenableBuilder<int>(
                valueListenable:
                    NotificationBadgeService.instance.unreadCount,
                builder: (context, count, _) {
                  if (count <= 0) return const SizedBox.shrink();
                  return _UnreadDot(count: count);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Red pill on the bell showing how many pushes arrived since the
/// notifications screen was last opened (capped at 99+).
class _UnreadDot extends StatelessWidget {
  const _UnreadDot({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFE53935),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.white, width: 1.5),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.imageUrl,
    required this.size,
    required this.iconSize,
    required this.borderWidth,
    this.backgroundColor,
  });

  final String imageUrl;
  final double size;
  final double iconSize;
  final double borderWidth;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.trim().isNotEmpty;
    final trimmedImage = imageUrl.trim();
    final isNetworkImage = trimmedImage.startsWith('http');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasImage
            ? null
            : const LinearGradient(
                colors: [
                  AppColors.avatarGradientStart,
                  AppColors.avatarGradientEnd,
                ],
              ),
        color: hasImage ? backgroundColor ?? AppColors.white : null,
        border: Border.all(color: AppColors.avatarBorder, width: borderWidth),
      ),
      child: ClipOval(
        child: hasImage
            ? isNetworkImage
                  ? Image.network(
                      trimmedImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _FallbackAvatarIcon(iconSize: iconSize),
                    )
                  : Image.file(
                      File(trimmedImage),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _FallbackAvatarIcon(iconSize: iconSize),
                    )
            : _FallbackAvatarIcon(iconSize: iconSize),
      ),
    );
  }
}

class _FallbackAvatarIcon extends StatelessWidget {
  const _FallbackAvatarIcon({required this.iconSize});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(Icons.person_rounded, color: AppColors.white, size: iconSize),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardTabbarController>();

    return _DashboardScaffold(
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppFeatureGate(
              feature: AppFeaturesService.dailyQuiz,
              child: Column(
                children: [_DailyQuizMiniCard(), SizedBox(height: 18)],
              ),
            ),
            const _LeaderboardStripCard(),
            const SizedBox(height: 18),
            if (controller.dashboardSummaryError.value.isNotEmpty)
              _DashboardInlineState(
                message: controller.dashboardSummaryError.value,
                onRetry: () => controller.loadDashboardData(force: true),
              )
            else ...[
              const _JourneyCard(),
              const SizedBox(height: 18),
            ],
            const _WeakAreasSection(),
            const SizedBox(height: 18),
            const AppFeatureGate(
              feature: AppFeaturesService.funFact,
              child: Column(children: [_FunFactCard(), SizedBox(height: 18)]),
            ),
            const AppFeatureGate(
              feature: AppFeaturesService.mockTest,
              child: _HomeMockTestCard(),
            ),
            const _LearningJourneyBanner(),
          ],
        ),
      ),
    );
  }
}

class _LearnTab extends GetView<DashboardTabbarController> {
  const _LearnTab();

  @override
  Widget build(BuildContext context) {
    return _DashboardScaffold(
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ChallengeBanner(),
            const SizedBox(height: 24),
            const Text(
              'My Subjects',
              style: TextStyle(
                color: AppColors.textHeadingAlt,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            if (controller.isLoadingLearnSubjects.value)
              const _LearnSubjectsSkeleton()
            else if (controller.learnSubjectsError.value.isNotEmpty)
              _DashboardInlineState(
                message: controller.learnSubjectsError.value,
                onRetry: () => controller.loadDashboardData(force: true),
              )
            else if (controller.learnSubjects.isEmpty)
              const _DashboardInlineState(
                message: 'No subjects available right now.',
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.learnSubjects.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.90,
                ),
                itemBuilder: (context, index) {
                  final subject = controller.learnSubjects[index];
                  return _SubjectCard(subject: subject);
                },
              ),
            const SizedBox(height: 28),
            const Text(
              'Study Tools',
              style: TextStyle(
                color: AppColors.textHeadingAlt,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            // Study Tools drops entries (today: Notes) the admin switched off.
            AppFeaturesBuilder(
              builder: (context) => Column(
                children: controller.studyTools
                    .map(_StudyToolCard.new)
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizTab extends GetView<DashboardTabbarController> {
  const _QuizTab();

  @override
  Widget build(BuildContext context) {
    return _DashboardScaffold(
      child: Column(
        children: const [
          // Each card is its own admin-controlled section: when one is
          // switched off for this class it disappears along with its spacing.
          AppFeatureGate(
            feature: AppFeaturesService.dailyQuiz,
            child: Column(
              children: [_QuizChallengeCard(), SizedBox(height: 14)],
            ),
          ),
          AppFeatureGate(
            feature: AppFeaturesService.practiceQuiz,
            child: Column(
              children: [_QuizPracticeCard(), SizedBox(height: 14)],
            ),
          ),
          AppFeatureGate(
            feature: AppFeaturesService.mockTest,
            child: Column(children: [_MockTestCard(), SizedBox(height: 14)]),
          ),
          AppFeatureGate(
            feature: AppFeaturesService.dailyQuiz,
            child: Column(children: [_AnalyticsCard(), SizedBox(height: 14)]),
          ),
          AppFeatureGate(
            feature: AppFeaturesService.quizHistory,
            child: _PreviousResultsCard(),
          ),
        ],
      ),
    );
  }
}

class _LiveTab extends GetView<DashboardTabbarController> {
  const _LiveTab();

  @override
  Widget build(BuildContext context) {
    return _DashboardScaffold(
      child: Obx(() {
        if (controller.isLoadingLiveClasses.value) {
          return const _LiveClassesSkeleton();
        }

        if (controller.liveClassesError.value.isNotEmpty) {
          return _DashboardInlineState(
            message: controller.liveClassesError.value,
            onRetry: () => controller.loadLiveClasses(force: true),
          );
        }

        if (controller.liveClassSchedules.isEmpty) {
          return _DashboardInlineState(
            message: 'No live classes available right now.',
            onRetry: () => controller.loadLiveClasses(force: true),
          );
        }

        final featuredClass = controller.featuredLiveClass;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Live Class',
              style: TextStyle(
                color: AppColors.textHeadingAlt,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            if (featuredClass != null) ...[
              _LiveFeaturedCard(item: featuredClass),
              const SizedBox(height: 20),
            ],
            ...controller.liveClassSchedules.map(_LiveScheduleCard.new),
          ],
        );
      }),
    );
  }
}

class _ProfileTab extends GetView<DashboardTabbarController> {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return _DashboardScaffold(
      child: Column(
        children: [
          const SizedBox(height: 18),
          const _ProfileInfoCard(),
          const SizedBox(height: 14),
          const _ProfileStatsCard(),
          const SizedBox(height: 14),
          const AppFeatureGate(
            feature: AppFeaturesService.subscription,
            child: Column(
              children: [_SubscriptionBanner(), SizedBox(height: 18)],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cardShadow.withValues(alpha: 0.32),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            // The menu drops entries (today: Change Class) the admin switched
            // off, so it has to rebuild when a fresh answer lands.
            child: AppFeaturesBuilder(
              builder: (context) => Column(
                children: controller.profileMenuItems
                    .map((item) => _ProfileMenuTile(item: item))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            controller.appBuild,
            style: const TextStyle(
              color: AppColors.textMuted8,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardTabbarController>();

    return Obx(() {
      final summary = controller.lessonSummary.value;
      final subjects = controller.learnSubjects;

      return InkWell(
        onTap: () => controller.changeTab(1),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD8DEF0).withValues(alpha: 0.5),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6C4DF6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Learning Progress',
                          style: TextStyle(
                            color: Color(0xFF1B1F2A),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          summary.activeLessonLabel,
                          style: const TextStyle(
                            color: Color(0xFF8A8F9C),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _AnimatedProgressPercentLabel(
                    progressValue: summary.progressValue,
                  ),
                ],
              ),
              if (subjects.isNotEmpty) ...[
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final subject in subjects)
                      _SubjectChip(subject: subject),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              _AnimatedProgressBar(progressValue: summary.progressValue),
            ],
          ),
        ),
      );
    });
  }
}

/// Animates the "Completed" percentage label counting up from 0 to
/// [progressValue] once the header intro animation finishes.
class _AnimatedProgressPercentLabel extends StatefulWidget {
  const _AnimatedProgressPercentLabel({required this.progressValue});

  final double progressValue;

  @override
  State<_AnimatedProgressPercentLabel> createState() =>
      _AnimatedProgressPercentLabelState();
}

class _AnimatedProgressPercentLabelState
    extends State<_AnimatedProgressPercentLabel> {
  @override
  void initState() {
    super.initState();
    _headerIntroDone.addListener(_onHeaderIntroChanged);
  }

  @override
  void dispose() {
    _headerIntroDone.removeListener(_onHeaderIntroChanged);
    super.dispose();
  }

  void _onHeaderIntroChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final target = _headerIntroDone.value ? widget.progressValue : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: target),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return Text(
              '${(value * 100).round()}%',
              style: const TextStyle(
                color: Color(0xFF6C4DF6),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            );
          },
        ),
        const Text(
          'Completed',
          style: TextStyle(
            color: Color(0xFF8A8F9C),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Animates the linear progress bar filling from 0 to [progressValue]
/// once the header intro animation finishes.
class _AnimatedProgressBar extends StatefulWidget {
  const _AnimatedProgressBar({required this.progressValue});

  final double progressValue;

  @override
  State<_AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<_AnimatedProgressBar> {
  @override
  void initState() {
    super.initState();
    _headerIntroDone.addListener(_onHeaderIntroChanged);
  }

  @override
  void dispose() {
    _headerIntroDone.removeListener(_onHeaderIntroChanged);
    super.dispose();
  }

  void _onHeaderIntroChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final target = _headerIntroDone.value ? widget.progressValue : 0.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: target),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: const Color(0xFFEDEFF4),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6C4DF6)),
          );
        },
      ),
    );
  }
}

/// Compact subject pill: colored symbol + short name, so each subject is
/// visually identifiable at a glance.
class _SubjectChip extends StatelessWidget {
  const _SubjectChip({required this.subject});

  final SubjectCardData subject;

  @override
  Widget build(BuildContext context) {
    final color = _subjectColor(subject.title, subject.accent);
    final icon = _subjectIcon(subject.title, subject.icon);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 11, 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            subject.title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// A spread of bright, kid-friendly card colors.
const List<Color> _brightSubjectColors = [
  Color(0xFFFF5A5F), // coral red
  Color(0xFFFF8A3D), // orange
  Color(0xFFFFB300), // amber
  Color(0xFF22C55E), // green
  Color(0xFF06B6D4), // cyan
  Color(0xFF3B82F6), // blue
  Color(0xFF7C5CFC), // violet
  Color(0xFFEC4899), // pink
  Color(0xFF14B8A6), // teal
  Color(0xFFF43F5E), // rose
];

/// Picks a bright color that's stable for a given subject key (so a subject
/// always keeps the same color across rebuilds, but the set looks varied).
Color _brightSubjectColor(String key) {
  if (key.isEmpty) return _brightSubjectColors.first;
  var hash = 0;
  for (final unit in key.codeUnits) {
    hash = (hash + unit) & 0x7fffffff;
  }
  return _brightSubjectColors[hash % _brightSubjectColors.length];
}

/// Per-subject symbol, keyed by subject name. Falls back to the subject's
/// existing palette icon for anything not listed here.
IconData _subjectIcon(String name, IconData fallback) {
  final key = name.trim().toLowerCase();
  bool has(String s) => key.contains(s);

  if (has('math') || has('गणित')) return Icons.calculate_rounded;
  if (has('hindi') || has('हिंदी') || has('हिन्दी')) {
    return Icons.translate_rounded;
  }
  if (has('english') || has('अंग्रेज')) return Icons.menu_book_rounded;
  // Social Science contains "science", so this must be checked first.
  if (has('social') ||
      has('sst') ||
      has('history') ||
      has('civics') ||
      has('geograph') ||
      has('सामाजिक')) {
    return Icons.public_rounded;
  }
  if (has('science') || has('विज्ञान')) return Icons.science_rounded;
  if (has('computer') || has('coding') || has('comp')) {
    return Icons.computer_rounded;
  }
  if (has('sanskrit') || has('संस्कृत')) return Icons.auto_stories_rounded;
  if (has('evs') || has('environ')) return Icons.eco_rounded;
  if (has('gk') || has('general knowledge')) return Icons.lightbulb_rounded;
  return fallback;
}

/// Per-subject brand color, keyed by subject name. Falls back to the
/// index-based palette accent for any subject not listed here.
Color _subjectColor(String name, Color fallback) {
  final key = name.trim().toLowerCase();
  bool has(String s) => key.contains(s);

  if (has('math') || has('गणित')) return const Color(0xFF4A4FD9); // indigo
  if (has('hindi') || has('हिंदी') || has('हिन्दी')) {
    return const Color(0xFFE4572E); // warm red
  }
  if (has('english') || has('अंग्रेज')) return const Color(0xFF19945F); // green
  // Social Science contains "science", so this must be checked first.
  if (has('social') ||
      has('sst') ||
      has('history') ||
      has('civics') ||
      has('geograph') ||
      has('सामाजिक')) {
    return const Color(0xFF8A2CD5); // purple
  }
  if (has('science') || has('विज्ञान')) {
    return const Color(0xFFE8590C); // orange
  }
  if (has('computer') || has('coding') || has('comp')) {
    return const Color(0xFF1671D9); // blue
  }
  if (has('sanskrit') || has('संस्कृत')) {
    return const Color(0xFFB8860B); // amber
  }
  if (has('evs') || has('environ')) return const Color(0xFF12A594); // teal
  if (has('gk') || has('general knowledge')) {
    return const Color(0xFFD6336C); // pink
  }
  return fallback;
}

/// Horizontal, story-style strip of the child's own subjects. Sits above the
/// Daily Quiz card on the Home tab.
class _FunFactCard extends StatefulWidget {
  const _FunFactCard();

  /// Ring size, label gap and label line height. Kept here so the strip's
  /// SizedBox height below stays in sync with the item it holds.
  static const double _ringSize = 62;
  static const double _labelGap = 8;
  static const double _labelHeight = 16;

  @override
  State<_FunFactCard> createState() => _FunFactCardState();
}

class _FunFactCardState extends State<_FunFactCard> {
  /// URLs already handed to the image cache, so a rebuild does not re-warm
  /// what is already warm.
  final Set<String> _warmedUrls = <String>{};

  /// Decodes each story's opening image ahead of the tap, so the story opens
  /// on a picture rather than a spinner.
  void _warmStoryImages() {
    if (!mounted) {
      return;
    }
    for (final url in FunFactController.instance.openingImageUrls) {
      if (_warmedUrls.add(url)) {
        final startedAt = DateTime.now();
        // onError is required, not optional: precacheImage completes normally
        // on failure and raises an unhandled framework error without it. A
        // deleted fun fact must not surface as a crash on the Home tab.
        precacheImage(
          funFactImage(url),
          context,
          onError: (_, _) => debugPrint('[FunFact] warm FAILED: $url'),
        ).then((_) {
          debugPrint(
            '[FunFact] warmed in '
            '${DateTime.now().difference(startedAt).inMilliseconds}ms: $url',
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardTabbarController>();

    return Obx(() {
      // Read inside the Obx so this rebuilds as the preload lands, then warm
      // after the frame — precaching is a side effect and cannot run in build.
      final openingUrls = FunFactController.instance.openingImageUrls;
      if (openingUrls.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _warmStoryImages());
      }

      // Optional strip: nothing to show without subjects, so drop the whole
      // card rather than leaving an empty box on the Home tab.
      if (controller.learnSubjectsError.value.isNotEmpty ||
          (!controller.isLoadingLearnSubjects.value &&
              controller.learnSubjects.isEmpty)) {
        return const SizedBox.shrink();
      }

      final isLoading = controller.isLoadingLearnSubjects.value;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 0, 16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fun Fact',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height:
                  _FunFactCard._ringSize +
                  _FunFactCard._labelGap +
                  _FunFactCard._labelHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 18),
                itemCount: isLoading ? 4 : controller.learnSubjects.length,
                separatorBuilder: (_, _) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  if (isLoading) {
                    return const _FunFactSkeletonItem();
                  }
                  return _FunFactSubjectItem(
                    subject: controller.learnSubjects[index],
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _FunFactSubjectItem extends StatelessWidget {
  const _FunFactSubjectItem({required this.subject});

  final SubjectCardData subject;

  /// Stories with anything left to watch get the warm gradient; the ring only
  /// goes flat grey once the whole batch has been seen, the same signal
  /// Instagram uses.
  static const LinearGradient _unwatchedRing = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Color(0xFFF97C3C), Color(0xFFDD2A7B)],
  );
  static const LinearGradient _watchedRing = LinearGradient(
    colors: [Color(0xFFD8DAE0), Color(0xFFD8DAE0)],
  );

  void _openStory() {
    final accent = _subjectColor(subject.title, subject.accent);
    Get.to<void>(
      () => FunFactStoryViews(
        subjectId: subject.subjectId,
        subjectTitle: subject.title,
        subjectIcon: _subjectIcon(subject.title, subject.icon),
        subjectAccent: accent,
        subjectIconBackground: accent.withValues(alpha: 0.12),
      ),
      fullscreenDialog: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Match the icon and accent to the subject by name — the same mapping the
    // other subject chips use. The palette on SubjectCardData is index-based, so
    // reading subject.icon directly gives the wrong glyph (e.g. a flask on
    // Hindi); resolve by title instead.
    final icon = _subjectIcon(subject.title, subject.icon);
    final accent = _subjectColor(subject.title, subject.accent);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _openStory,
          child: Obx(
            () => Container(
              width: _FunFactCard._ringSize,
              height: _FunFactCard._ringSize,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient:
                    FunFactController.instance.isCompleted(subject.subjectId)
                    ? _watchedRing
                    : _unwatchedRing,
              ),
              // White gap between the ring and the icon disc.
              child: Container(
                padding: const EdgeInsets.all(2.5),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.12),
                  ),
                  child: Icon(icon, color: accent, size: 24),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: _FunFactCard._labelGap),
        SizedBox(
          width: 72,
          height: _FunFactCard._labelHeight,
          child: Text(
            subject.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.neutralText5,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _FunFactSkeletonItem extends StatelessWidget {
  const _FunFactSkeletonItem();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ShimmerBox(
          width: _FunFactCard._ringSize,
          height: _FunFactCard._ringSize,
          radius: _FunFactCard._ringSize / 2,
        ),
        SizedBox(height: _FunFactCard._labelGap),
        _ShimmerBox(width: 52, height: 10, radius: 5),
      ],
    );
  }
}

class _DailyQuizMiniCard extends GetView<DashboardTabbarController> {
  const _DailyQuizMiniCard();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.to(() => const StartQuizViews()),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        height: 212,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF1B2C8A),
          borderRadius: BorderRadius.circular(24),
          image: const DecorationImage(
            image: AssetImage('assets/quizz.jpg'),
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _BounceLoop(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC833),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFF1B2C8A),
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Obx(
                        () => Text(
                          controller.userXpSummary.value.dailyQuizXpLabel,
                          style: const TextStyle(
                            color: Color(0xFF1B2C8A),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Text(
                'Daily Quiz',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'Test your knowledge daily\nand level up!',
                style: TextStyle(
                  color: Color(0xFFD7DCF5),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              _BounceLoop(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Start Quiz',
                        style: TextStyle(
                          color: Color(0xFF4D4FE1),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xFF4D4FE1),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wraps [child] in a small, continuous, subtle up-and-down bounce.
class _BounceLoop extends StatefulWidget {
  const _BounceLoop({
    required this.child,
    this.pixelRange = 4,
    this.duration = const Duration(milliseconds: 900),
  });

  final Widget child;
  final double pixelRange;
  final Duration duration;

  @override
  State<_BounceLoop> createState() => _BounceLoopState();
}

class _BounceLoopState extends State<_BounceLoop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    _offset = Tween<double>(
      begin: 0,
      end: -widget.pixelRange,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offset,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _offset.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _HomeMockTestCard extends StatelessWidget {
  const _HomeMockTestCard();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardTabbarController>();

    return Obx(() {
      final mockTest = controller.liveMockTest;
      if (controller.isLoadingMockTests.value ||
          controller.mockTestsError.value.isNotEmpty ||
          mockTest == null) {
        return const SizedBox.shrink();
      }

      return Column(
        children: [
          _MockTestHeroCard(
            mockTest: mockTest,
            onFinished: controller.reloadQuizTabData,
          ),
          const SizedBox(height: 18),
        ],
      );
    });
  }
}

class _MockTestHeroCard extends StatelessWidget {
  const _MockTestHeroCard({required this.mockTest, required this.onFinished});

  final MockTestCardData mockTest;
  final Future<void> Function() onFinished;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (!mockTest.canStart) {
          Get.snackbar(
            'Mock Test',
            mockTest.attemptStatus == 'attempted'
                ? 'You have already attempted this mock test.'
                : 'Mock test is ${mockTest.statusLabel.toLowerCase()}.',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
        Get.to(() => StartQuizViews(mockTestId: mockTest.id))?.then((_) {
          onFinished();
        });
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        height: 236,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F3D91), Color(0xFF126A85), Color(0xFF12A594)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF126A85).withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              bottom: -18,
              child: Image.asset(
                'assets/mock_test.png',
                width: 160,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              right: 18,
              top: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: Text(
                  mockTest.statusLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC833),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_rounded,
                          color: Color(0xFF0F3D91),
                          size: 14,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'MOCK TEST',
                          style: TextStyle(
                            color: Color(0xFF0F3D91),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: 210,
                    child: Text(
                      mockTest.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(
                    width: 190,
                    child: Text(
                      'Real exam simulation\nwith timers.',
                      style: TextStyle(
                        color: Color(0xFFE2FFF6),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        constraints: const BoxConstraints(maxWidth: 185),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.event_note_rounded,
                              color: Color(0xFFFFD365),
                              size: 15,
                            ),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                mockTest.windowLabel,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(23),
                        ),
                        child: Icon(
                          mockTest.canStart
                              ? Icons.arrow_forward_rounded
                              : Icons.lock_clock_rounded,
                          color: const Color(0xFF126A85),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Blue hero banner at the top of the Home tab (uses assets/head.jpg).
class _LearningJourneyBanner extends StatelessWidget {
  const _LearningJourneyBanner();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1568 / 470,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF4B43D6),
          borderRadius: BorderRadius.circular(24),
          image: const DecorationImage(
            image: AssetImage('assets/head.jpg'),
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
          child: Row(
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Your Learning Journey',
                        maxLines: 1,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Master your goals with\nAI-powered learning.',
                      style: TextStyle(
                        color: Color(0xFFD7DCF5),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Expanded(flex: 4, child: SizedBox()),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiTutorCard extends StatelessWidget {
  const _AiTutorCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration().copyWith(
        color: AppColors.neutralSurface,
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: AppColors.purpleSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.purple,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'AI Tutor',
            style: TextStyle(
              color: AppColors.neutralText,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Ask any doubt\ninstant solutions.',
            style: TextStyle(
              color: AppColors.textMuted7,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.neutralSurface2,
              border: Border.all(color: AppColors.softBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.textMuted7,
                  size: 14,
                ),
                SizedBox(width: 6),
                Text(
                  'Locked',
                  style: TextStyle(
                    color: AppColors.textMuted7,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardStripCard extends StatelessWidget {
  const _LeaderboardStripCard();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardTabbarController>();

    return Obx(() {
      final summary = controller.leaderboardSummary.value;

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.emoji_events_rounded,
                        color: Color(0xFFFFB300),
                        size: 22,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Leaderboard',
                        style: TextStyle(
                          color: AppColors.textPrimaryNavy,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _AvatarStack(summary: summary),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  controller.isLoadingLeaderboardSummary.value
                      ? 'Global Rank: ...'
                      : 'Global Rank: ${summary.rankText}',
                  style: const TextStyle(
                    color: Color(0xFF4D4FE1),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                InkWell(
                  onTap: controller.openLeaderboard,
                  borderRadius: BorderRadius.circular(26),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: const Color(0xFF4D4FE1)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Ranking',
                          style: TextStyle(
                            color: Color(0xFF4D4FE1),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 7),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFF4D4FE1),
                          size: 15,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

/// Home-tab entry point into the student's weak subjects: the worst ones as a
/// swipeable row, and a way through to the full list.
class _WeakAreasSection extends GetView<DashboardTabbarController> {
  const _WeakAreasSection();

  /// Ring + name + meta + bar + CTA, plus the card's own padding.
  static const double _carouselHeight = 166;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final summary = controller.weakAreasSummary.value;
      final subjects = summary.subjects;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFEBEEF8)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9AA4C8).withValues(alpha: 0.13),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Flexible(
                            child: Text(
                              'Improvement Areas',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFF151935),
                                fontSize: 16.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          if (subjects.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF0FF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${subjects.length}',
                                style: const TextStyle(
                                  color: Color(0xFF4B3FD8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Your weakest subjects right now',
                        style: TextStyle(
                          color: Color(0xFF6B7192),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _SeeAllChip(
                  onTap: () => Get.toNamed(AppRoutes.improvementAreas),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (controller.isLoadingWeakAreas.value)
              const _WeakAreasSkeleton()
            else if (controller.weakAreasError.value.isNotEmpty)
              _DashboardInlineState(
                message: controller.weakAreasError.value,
                onRetry: () => controller.loadWeakAreas(force: true),
              )
            else if (subjects.isEmpty)
              _WeakAreasEmptyState(hasAttempts: summary.hasAttempts)
            else
              SizedBox(
                height: _carouselHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: subjects.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => _WeakAreaTile(
                    subject: subjects[index],
                    isTopPriority: index == 0,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _SeeAllChip extends StatelessWidget {
  const _SeeAllChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEEF0FF),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.fromLTRB(12, 7, 9, 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'See All',
                style: TextStyle(
                  color: Color(0xFF4B3FD8),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: 3),
              Icon(
                Icons.arrow_forward_rounded,
                color: Color(0xFF4B3FD8),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeakAreasEmptyState extends StatelessWidget {
  const _WeakAreasEmptyState({required this.hasAttempts});

  final bool hasAttempts;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EBF6)),
      ),
      child: Column(
        children: [
          Icon(
            hasAttempts
                ? Icons.verified_rounded
                : Icons.insights_rounded,
            color: const Color(0xFF4B3FD8),
            size: 26,
          ),
          const SizedBox(height: 10),
          Text(
            hasAttempts
                ? 'Nothing to fix right now — every subject is above the mark!'
                : 'Attempt a quiz and we will show you exactly what to practise.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6B7192),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// One subject in the Home carousel. Tapping it opens the weak lessons behind
/// that subject, the same sheet the full screen uses.
class _WeakAreaTile extends StatelessWidget {
  const _WeakAreaTile({required this.subject, required this.isTopPriority});

  final WeakAreaSubjectData subject;

  /// The worst subject is outlined and badged, so there is one obvious start.
  final bool isTopPriority;

  @override
  Widget build(BuildContext context) {
    final accent = _weakAreaAccent(subject.name);
    final mastery = subject.accuracy.clamp(0, 100).toDouble();

    return SizedBox(
      width: 172,
      child: Material(
        color: const Color(0xFFF8F9FE),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => showWeakAreaLessonsBottomSheet(
            context,
            subject,
            dashboardController: Get.find<DashboardTabbarController>(),
          ),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isTopPriority
                    ? accent.withValues(alpha: 0.38)
                    : const Color(0xFFE8EBF6),
                width: isTopPriority ? 1.4 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _WeakAreaRing(
                      percent: mastery,
                      accent: accent,
                      label: subject.accuracyLabel,
                    ),
                    const Spacer(),
                    if (isTopPriority)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'FOCUS',
                          style: TextStyle(
                            color: accent,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  subject.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF151935),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${subject.correct}/${subject.answered} correct'
                  '${subject.skipped > 0 ? '  ·  ${subject.skipped} skipped' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B7192),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    value: mastery / 100,
                    backgroundColor: const Color(0xFFE8EBF6),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'Practice',
                      style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: accent,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mastery as a small ring with the figure inside it.
class _WeakAreaRing extends StatelessWidget {
  const _WeakAreaRing({
    required this.percent,
    required this.accent,
    required this.label,
  });

  final double percent;
  final Color accent;
  final String label;

  @override
  Widget build(BuildContext context) {
    // Guarded so a stray value from the API can never reach the painter.
    final safePercent = percent.isNaN ? 0.0 : percent.clamp(0, 100).toDouble();

    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: safePercent / 100,
              strokeWidth: 4,
              strokeCap: StrokeCap.round,
              backgroundColor: accent.withValues(alpha: 0.14),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(7),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: accent,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeLiveClassesSection extends GetView<DashboardTabbarController> {
  const _HomeLiveClassesSection();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final featuredClass = controller.featuredLiveClass;
      if (controller.isLoadingLiveClasses.value ||
          controller.liveClassesError.value.isNotEmpty ||
          featuredClass == null ||
          featuredClass.computedPhase != 'live') {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 18),
          const Text(
            'Live Classes',
            style: TextStyle(
              color: AppColors.textPrimaryNavy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          _LiveFeaturedCard(item: featuredClass),
        ],
      );
    });
  }
}

class _SpokenEnglishCard extends StatelessWidget {
  const _SpokenEnglishCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration().copyWith(
        color: AppColors.neutralSurface,
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: AppColors.purpleSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.purple,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Spoken English',
            style: TextStyle(
              color: AppColors.neutralText,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Practice with AI Tutor',
            style: TextStyle(
              color: AppColors.textMuted7,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.neutralSurface2,
              border: Border.all(color: AppColors.softBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.textMuted7,
                  size: 14,
                ),
                SizedBox(width: 6),
                Text(
                  'Locked',
                  style: TextStyle(
                    color: AppColors.textMuted7,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreClassesCard extends StatelessWidget {
  const _ExploreClassesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: AppColors.purpleSoft2,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.travel_explore,
              color: AppColors.purpleDark,
              size: 25,
            ),
          ),
          const SizedBox(width: 18),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explore Classes',
                  style: TextStyle(
                    color: AppColors.textPrimaryAlt,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Explore your learning path.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textMuted4,
            size: 28,
          ),
        ],
      ),
    );
  }
}

class _ChallengeBanner extends StatelessWidget {
  const _ChallengeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // padding: const EdgeInsets.all(24),
      // decoration: BoxDecoration(
      //   color: const Color(0xFF2E3236),
      //   borderRadius: BorderRadius.circular(30),
      // ),
      // child: const Column(
      //   crossAxisAlignment: CrossAxisAlignment.start,
      //   children: [
      //     DecoratedBox(
      //       decoration: BoxDecoration(
      //         color: Color(0xFF5A5FEF),
      //         borderRadius: BorderRadius.all(Radius.circular(18)),
      //       ),
      //       child: Padding(
      //         padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      //         child: Text(
      //           'Daily Challenge',
      //           style: TextStyle(
      //             color: Colors.white,
      //             fontSize: 12,
      //             fontWeight: FontWeight.w700,
      //           ),
      //         ),
      //       ),
      //     ),
      //     SizedBox(height: 13),
      //     Text(
      //       'Mastering Trigonometry',
      //       style: TextStyle(
      //         color: Colors.white,
      //         fontSize: 18,
      //         fontWeight: FontWeight.w800,
      //       ),
      //     ),
      //     SizedBox(height: 12),
      //     Text(
      //       'Solve today\'s featured problems to earn double XP\nand unlock the "Math Wizard" badge.',
      //       style: TextStyle(
      //         color: Color(0xFFE4E7ED),
      //         fontSize: 13,
      //         fontWeight: FontWeight.w500,
      //         height: 1.65,
      //       ),
      //     ),
      //     SizedBox(height: 16),
      //     _BannerButton(text: 'Start Challenge'),
      //   ],
      // ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subject});

  final SubjectCardData subject;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardTabbarController>();
    final accent = _brightSubjectColor(
      subject.subjectId.isNotEmpty ? subject.subjectId : subject.title,
    );
    final icon = _subjectIcon(subject.title, subject.icon);

    return InkWell(
      onTap: () => controller.openLearnSubjectFromCard(subject),
      borderRadius: BorderRadius.circular(26),
      child: Container(
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const Spacer(),
            Text(
              subject.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: subject.progressValue,
                      minHeight: 8,
                      backgroundColor: accent.withValues(alpha: 0.18),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  subject.progressLabel,
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.92),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              subject.progressText,
              style: TextStyle(
                color: accent,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardInlineState extends StatelessWidget {
  const _DashboardInlineState({required this.message, this.onRetry});

  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.resultMeta,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onRetry,
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({this.width, required this.height, this.radius = 12});

  final double? width;
  final double height;
  final double radius;

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + (_controller.value * 2), 0),
              end: Alignment(0.2 + (_controller.value * 2), 0),
              colors: const [
                Color(0xFFE9EEF8),
                Color(0xFFF7F9FE),
                Color(0xFFE9EEF8),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LearnSubjectsSkeleton extends StatelessWidget {
  const _LearnSubjectsSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.90,
      ),
      itemBuilder: (context, index) => Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ShimmerBox(width: 42, height: 42, radius: 12),
            Spacer(),
            _ShimmerBox(width: 94, height: 14, radius: 7),
            SizedBox(height: 10),
            _ShimmerBox(height: 8, radius: 4),
            SizedBox(height: 8),
            _ShimmerBox(width: 74, height: 10, radius: 5),
          ],
        ),
      ),
    );
  }
}

class _LiveClassesSkeleton extends StatelessWidget {
  const _LiveClassesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ShimmerBox(width: 96, height: 16, radius: 8),
        const SizedBox(height: 18),
        Container(
          height: 170,
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ShimmerBox(width: 130, height: 16, radius: 8),
              SizedBox(height: 12),
              _ShimmerBox(height: 10, radius: 5),
              SizedBox(height: 8),
              _ShimmerBox(width: 180, height: 10, radius: 5),
              Spacer(),
              _ShimmerBox(width: 110, height: 34, radius: 17),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeakAreasSkeleton extends StatelessWidget {
  const _WeakAreasSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _WeakAreasSection._carouselHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => Container(
          width: 172,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FE),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EBF6)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ShimmerBox(width: 44, height: 44, radius: 22),
                  Spacer(),
                  _ShimmerBox(width: 42, height: 16, radius: 8),
                ],
              ),
              SizedBox(height: 12),
              _ShimmerBox(width: 104, height: 13, radius: 6),
              SizedBox(height: 7),
              _ShimmerBox(width: 78, height: 10, radius: 5),
              Spacer(),
              _ShimmerBox(width: double.infinity, height: 5, radius: 3),
              SizedBox(height: 12),
              _ShimmerBox(width: 64, height: 11, radius: 5),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyticsSkeleton extends StatelessWidget {
  const _AnalyticsSkeleton();

  @override
  Widget build(BuildContext context) {
    // 12 (title) + 18 (gap) + 124 (tallest bar) = 154.
    return const SizedBox(
      height: 154,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerBox(width: 170, height: 12, radius: 6),
          SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _ShimmerBox(height: 76, radius: 10)),
              SizedBox(width: 8),
              Expanded(child: _ShimmerBox(height: 112, radius: 10)),
              SizedBox(width: 8),
              Expanded(child: _ShimmerBox(height: 92, radius: 10)),
              SizedBox(width: 8),
              Expanded(child: _ShimmerBox(height: 124, radius: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudyToolCard extends StatelessWidget {
  const _StudyToolCard(this.tool);

  final StudyToolData tool;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardTabbarController>();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => controller.openStudyTool(tool),
        borderRadius: BorderRadius.circular(26),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: tool.iconBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(tool.icon, color: tool.accent, size: 28),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tool.subtitle,
                      style: const TextStyle(
                        color: AppColors.neutralText5,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.neutralText6,
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizChallengeCard extends GetView<DashboardTabbarController> {
  const _QuizChallengeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF1B2C8A),
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: AssetImage('assets/quizz.jpg'),
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Text('⚡', style: TextStyle(fontSize: 13)),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'DAILY CHALLENGE',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFFFFC833),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141F5E),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFC833),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Obx(
                        () => Text(
                          controller.userXpSummary.value.dailyQuizXpLabel,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Daily Quiz',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const SizedBox(
              width: 210,
              child: Text(
                'Test your knowledge with \n5 quick '
                'questions and earn \na 2x XP multiplier!',
                style: TextStyle(
                  color: Color(0xFFD7DCF5),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => Get.to(() => const StartQuizViews()),
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Start Challenge',
                      style: TextStyle(
                        color: Color(0xFF2A2D8F),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFF2A2D8F),
                      size: 18,
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

class _QuizPracticeCard extends StatelessWidget {
  const _QuizPracticeCard();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.to(() => const QuizPracticePaperSubjectViews()),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Stack(
          children: [
            Positioned(
              right: -4,
              top: 30,
              bottom: -4,
              child: Image.asset(
                'assets/3_books.png',
                width: 122,
                fit: BoxFit.contain,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.purpleSoft2,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Image.asset(
                        'assets/book.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 2),
                          Text(
                            'Practice Quiz',
                            style: TextStyle(
                              color: AppColors.textHeading,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Chapter-wise focused\npractice sessions.',
                            style: TextStyle(
                              color: AppColors.textSecondaryAlt,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.textHeading,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.only(right: 118),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: const [
                        _SubjectTag(
                          label: 'Mathematics',
                          background: Color(0xFFEDEBFF),
                          textColor: Color(0xFF5A3FE0),
                        ),
                        SizedBox(width: 8),
                        _SubjectTag(
                          label: 'Science',
                          background: Color(0xFFE3F6EC),
                          textColor: Color(0xFF17935F),
                        ),
                        SizedBox(width: 8),
                        _SubjectTag(
                          label: 'Social',
                          background: Color(0xFFFDEDE3),
                          textColor: Color(0xFFE0662E),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MockTestCard extends StatelessWidget {
  const _MockTestCard();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final dashboardController = Get.find<DashboardTabbarController>();
      final mockTest = dashboardController.mockTests.isNotEmpty
          ? dashboardController.mockTests.first
          : null;

      if (mockTest != null) {
        return _MockTestHeroCard(
          mockTest: mockTest,
          onFinished: dashboardController.reloadQuizTabData,
        );
      }

      return InkWell(
        onTap: mockTest == null
            ? null
            : () {
                if (!mockTest.canStart) {
                  Get.snackbar(
                    'Mock Test',
                    mockTest.attemptStatus == 'attempted'
                        ? 'You have already attempted this mock test.'
                        : 'Mock test is ${mockTest.statusLabel.toLowerCase()}.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  return;
                }
                Get.to(() => StartQuizViews(mockTestId: mockTest.id))?.then((
                  _,
                ) {
                  dashboardController.reloadQuizTabData();
                });
              },
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.warningSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Image.asset('assets/calendar.png', fit: BoxFit.contain),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            mockTest?.title ?? 'Mock Test',
                            style: const TextStyle(
                              color: AppColors.textHeading,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (mockTest != null) ...[
                          const SizedBox(width: 8),
                          _MockStatusBadge(status: mockTest.statusLabel),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dashboardController.isLoadingMockTests.value
                          ? 'Loading mock tests...'
                          : (dashboardController.mockTestsError.value.isNotEmpty
                                ? dashboardController.mockTestsError.value
                                : 'Real exam simulation with timers.'),
                      style: const TextStyle(
                        color: AppColors.textSecondaryAlt,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF0F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.calendar_month_rounded,
                                  color: Color(0xFF5A5FEF),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    mockTest?.windowLabel ??
                                        'No mock test available',
                                    style: const TextStyle(
                                      color: AppColors.neutralText4,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.textHeading,
                          size: 22,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _AnalyticsCard extends GetView<DashboardTabbarController> {
  const _AnalyticsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bar_chart_rounded,
                color: Color(0xFF5A5FEF),
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                'Daily Quiz Analytics',
                style: TextStyle(
                  color: AppColors.textHeading,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: controller.loadDailyQuizAnalytics,
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        color: Color(0xFF5A5FEF),
                        size: 18,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Refresh',
                        style: TextStyle(
                          color: Color(0xFF5A5FEF),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Obx(() {
            if (controller.isLoadingDailyQuizAnalytics.value) {
              return const _AnalyticsSkeleton();
            }

            if (controller.dailyQuizAnalyticsError.value.isNotEmpty) {
              return _DashboardInlineState(
                message: controller.dailyQuizAnalyticsError.value,
                onRetry: () => controller.loadDailyQuizAnalytics(force: true),
              );
            }

            final days = controller.dailyQuizAnalytics.isEmpty
                ? DailyQuizAnalyticsDayData.weekDefaults()
                : controller.dailyQuizAnalytics.toList();
            final attemptedCount = days.where((day) => day.isAttempted).length;
            final average = attemptedCount == 0
                ? 0
                : (days
                              .where((day) => day.isAttempted)
                              .fold<double>(
                                0,
                                (sum, day) => sum + day.percentage,
                              ) /
                          attemptedCount)
                      .round();
            final earnedThisWeek = days
                .where((day) => day.isAttempted)
                .fold<int>(
                  0,
                  (sum, day) => sum + (day.attempt?.totalScore ?? 0),
                );
            final currentStreak = controller.userXpSummary.value.streakCount;

            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _AnalyticsRing(percentage: average.toDouble()),
                    const SizedBox(width: 14),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: days
                              .map((day) => _AnalyticsDayItem(day: day))
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // const Divider(height: 1, thickness: 1, color: Color(0xFFEDEFF4)),
                // const SizedBox(height: 14),
                // Row(
                //   children: [
                //     Expanded(
                //       child: _AnalyticsStat(
                //         emoji: '🔥',
                //         value: '$currentStreak Day',
                //         label: 'Current Streak',
                //       ),
                //     ),
                //     Container(width: 1, height: 34, color: const Color(0xFFEDEFF4)),
                //     Expanded(
                //       child: _AnalyticsStat(
                //         emoji: '⭐',
                //         value: '$earnedThisWeek XP',
                //         label: 'Earned This Week',
                //       ),
                //     ),
                //     Container(width: 1, height: 34, color: const Color(0xFFEDEFF4)),
                //     Expanded(
                //       child: _AnalyticsStat(
                //         emoji: '📊',
                //         value: '$attemptedCount',
                //         label: 'Quizzes Attempted',
                //       ),
                //     ),
                //   ],
                // ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _AnalyticsRing extends StatelessWidget {
  const _AnalyticsRing({required this.percentage});

  final double percentage;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      height: 118,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 118,
            height: 118,
            child: CircularProgressIndicator(
              value: (percentage / 100).clamp(0.0, 1.0),
              strokeWidth: 11,
              strokeCap: StrokeCap.round,
              backgroundColor: const Color(0xFFEDECFB),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF6C63F0),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${percentage.round()}%',
                style: const TextStyle(
                  color: AppColors.textHeading,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'This Week',
                style: TextStyle(
                  color: AppColors.resultMeta,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnalyticsDayItem extends StatelessWidget {
  const _AnalyticsDayItem({required this.day});

  final DailyQuizAnalyticsDayData day;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color iconColor;
    final Color background;

    if (day.isComingSoon) {
      icon = Icons.access_time_rounded;
      iconColor = const Color(0xFF6C63F0);
      background = const Color(0xFFEDECFB);
    } else if (day.isAttempted) {
      icon = day.attempt!.passed
          ? Icons.sentiment_very_satisfied_rounded
          : Icons.sentiment_neutral_rounded;
      iconColor = day.accent;
      background = day.accent.withValues(alpha: 0.14);
    } else {
      icon = Icons.sentiment_dissatisfied_rounded;
      iconColor = const Color(0xFFAEB4C0);
      background = const Color(0xFFF0F2F6);
    }

    return SizedBox(
      width: 56,
      child: Column(
        children: [
          SizedBox(
            height: 26,
            child: Center(
              child: Text(
                day.statusText,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: day.isComingSoon
                      ? const Color(0xFF6C63F0)
                      : day.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            day.label,
            style: const TextStyle(
              color: AppColors.analyticsLabel,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsStat extends StatelessWidget {
  const _AnalyticsStat({
    required this.emoji,
    required this.value,
    required this.label,
  });

  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 5),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textHeading,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.resultMeta,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PreviousResultsCard extends StatefulWidget {
  const _PreviousResultsCard();

  @override
  State<_PreviousResultsCard> createState() => _PreviousResultsCardState();
}

class _PreviousResultsCardState extends State<_PreviousResultsCard> {
  bool _isLoading = true;
  String _dailyErrorMessage = '';
  String _practiceErrorMessage = '';
  String _mockErrorMessage = '';
  List<QuizSubmitResultItem> _dailyResults = const [];
  List<QuizSubmitResultItem> _practiceResults = const [];
  List<QuizSubmitResultItem> _mockResults = const [];
  int _dailyTotal = 0;
  int _practiceTotal = 0;
  int _mockTotal = 0;
  Worker? _refreshWorker;

  @override
  void initState() {
    super.initState();
    // Reload whenever the Quiz tab is (re)opened so history stays fresh.
    final controller = Get.find<DashboardTabbarController>();
    _refreshWorker = ever<int>(controller.quizHistoryRefreshTick, (_) {
      if (mounted) {
        _loadResults(silent: true);
      }
    });
    // The tabs live in an IndexedStack, so this card is built at launch even
    // while Home is showing. Fetching here would spend three requests on a
    // card nobody is looking at — opening the Quiz tab bumps the tick above,
    // which loads it.
    // Until then it keeps its initial spinner, which nobody sees anyway.
    if (controller.currentTabIndex.value == _quizTabIndex) {
      _loadResults();
    }
  }

  /// Index of the Quiz tab in the dashboard's IndexedStack.
  static const int _quizTabIndex = 2;

  /// How many attempts of this type the student actually has.
  ///
  /// This card only fetches the first couple of rows, so counting the rows is
  /// what made a student who had given 3 practice tests read "2 recent
  /// results". The server's pagination total is the real figure; the fetched
  /// rows are only used as a floor for it, in case the endpoint leaves
  /// `total` at 0.
  static int _totalOf(ApiResponse<QuizSubmitResultPage> response) {
    final page = response.data;
    if (page == null) {
      return 0;
    }
    final fetched = page.results.length;
    return page.pagination.total > fetched ? page.pagination.total : fetched;
  }

  @override
  void dispose() {
    _refreshWorker?.dispose();
    super.dispose();
  }

  Future<void> _loadResults({bool silent = false}) async {
    // On a background refresh (tab reopen) keep the existing list visible
    // instead of flashing the full-card spinner.
    setState(() {
      if (!silent) {
        _isLoading = true;
      }
      _dailyErrorMessage = '';
      _practiceErrorMessage = '';
      _mockErrorMessage = '';
    });

    final responses = await Future.wait([
      // Same page the Quiz tab's weekly chart asks for, so the two share a
      // single `daily-quiz/my-attempts` round trip; only the first couple are
      // shown below.
      QuizSubmitResultRepository.fetchResults(
        type: ResultHistoryType.daily,
        limit: QuizSubmitResultRepository.quizTabSharedLimit,
        cacheFor: QuizSubmitResultRepository.quizTabShareWindow,
      ),
      QuizSubmitResultRepository.fetchResults(
        type: ResultHistoryType.practice,
        limit: 2,
      ),
      QuizSubmitResultRepository.fetchResults(
        type: ResultHistoryType.mock,
        limit: 2,
      ),
    ]);

    if (!mounted) {
      return;
    }

    final dailyResponse = responses[0];
    final practiceResponse = responses[1];
    final mockResponse = responses[2];

    setState(() {
      _isLoading = false;
      _dailyResults = (dailyResponse.data?.results ?? const [])
          .take(2)
          .toList();
      _practiceResults = practiceResponse.data?.results ?? const [];
      _mockResults = mockResponse.data?.results ?? const [];
      _dailyTotal = _totalOf(dailyResponse);
      _practiceTotal = _totalOf(practiceResponse);
      _mockTotal = _totalOf(mockResponse);
      _dailyErrorMessage = dailyResponse.success ? '' : dailyResponse.message;
      _practiceErrorMessage = practiceResponse.success
          ? ''
          : practiceResponse.message;
      _mockErrorMessage = mockResponse.success ? '' : mockResponse.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quiz History',
          style: TextStyle(
            color: AppColors.textHeading,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          _DashboardResultSection(
            title: 'Daily Quiz',
            emptyMessage: 'No daily quiz result yet.',
            errorMessage: _dailyErrorMessage,
            results: _dailyResults,
            totalCount: _dailyTotal,
            assetPath: 'assets/daily_quiz.png',
            accentColor: const Color(0xFF5A5FEF),
            backgroundColor: const Color(0xFFEDEBFF),
            borderColor: const Color(0xFFDCD9FA),
            onRetry: _loadResults,
            onViewAll: () => Get.to(
              () => const PreviewResultViews(
                initialType: ResultHistoryType.daily,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _DashboardResultSection(
            title: 'Practice Test',
            emptyMessage: 'No practice test result yet.',
            errorMessage: _practiceErrorMessage,
            results: _practiceResults,
            totalCount: _practiceTotal,
            assetPath: 'assets/practice_test.png',
            accentColor: const Color(0xFF17935F),
            backgroundColor: const Color(0xFFE7F6EE),
            borderColor: const Color(0xFFC7E9D6),
            onRetry: _loadResults,
            onViewAll: () => Get.to(
              () => const PreviewResultViews(
                initialType: ResultHistoryType.practice,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _DashboardResultSection(
            title: 'Mock Test',
            emptyMessage: 'No mock test result yet.',
            errorMessage: _mockErrorMessage,
            results: _mockResults,
            totalCount: _mockTotal,
            assetPath: 'assets/mock_test.png',
            accentColor: const Color(0xFFF1670C),
            backgroundColor: const Color(0xFFFFF4E6),
            borderColor: const Color(0xFFFFE0AE),
            onRetry: _loadResults,
            onViewAll: () => Get.to(
              () =>
                  const PreviewResultViews(initialType: ResultHistoryType.mock),
            ),
          ),
        ],
      ],
    );
  }
}

class _DashboardResultSection extends StatelessWidget {
  const _DashboardResultSection({
    required this.title,
    required this.emptyMessage,
    required this.errorMessage,
    required this.results,
    required this.totalCount,
    required this.assetPath,
    required this.accentColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.onRetry,
    required this.onViewAll,
  });

  final String title;
  final String emptyMessage;
  final String errorMessage;
  final List<QuizSubmitResultItem> results;

  /// Every attempt the student has of this type, not just the rows fetched
  /// for this card — that is what the subtitle counts.
  final int totalCount;
  final String assetPath;
  final Color accentColor;
  final Color backgroundColor;
  final Color borderColor;
  final Future<void> Function() onRetry;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final subtitle = errorMessage.isNotEmpty
        ? errorMessage
        : (results.isEmpty
              ? emptyMessage
              : '$totalCount result${totalCount == 1 ? '' : 's'}');

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onViewAll,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: Image.asset(assetPath, fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.resultMeta,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: accentColor,
                      size: 22,
                    ),
                  ),
                ],
              ),
              if (errorMessage.isNotEmpty && results.isEmpty) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: onRetry,
                    child: Text(
                      'Retry',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentBadgesCard extends StatelessWidget {
  const _RecentBadgesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.softBorder2,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Recent Badges',
            style: TextStyle(
              color: AppColors.textHeading,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BadgeItem(
                label: 'Quiz Master',
                color: AppColors.badgeGold,
                icon: Icons.workspace_premium_rounded,
              ),
              _BadgeItem(
                label: 'Fastest Finisher',
                color: AppColors.primary,
                icon: Icons.speed_rounded,
              ),
              _BadgeItem(
                label: '7 Day Streak',
                color: AppColors.badgeLocked,
                icon: Icons.lock_outline_rounded,
                textColor: AppColors.badgeLockedText,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveFeaturedCard extends StatelessWidget {
  const _LiveFeaturedCard({required this.item});

  final LiveClassScheduleData item;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardTabbarController>();
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.softBorder2),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/live_backImage.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.black.withValues(alpha: 0.02),
                      AppColors.black.withValues(alpha: 0.34),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 28,
              top: 24,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.primaryBright,
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  child: Text(
                    item.subject,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 28,
              right: 28,
              bottom: 28,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.title}\nwith ${item.teacher}',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _LiveNowButton(
                    text: item.joinButtonLabel,
                    enabled: item.canJoin,
                    onTap: item.canJoin
                        ? () => controller.joinLiveClass(item)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveScheduleCard extends StatelessWidget {
  const _LiveScheduleCard(this.item);

  final LiveClassScheduleData item;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardTabbarController>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: _cardDecoration(borderRadius: 28),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Text(
                item.timeText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: item.accent,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                ),
              ),
            ),
            Container(
              width: 1,
              height: 110,
              color: AppColors.divider,
              margin: const EdgeInsets.symmetric(horizontal: 18),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: item.subjectColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      item.subject,
                      style: const TextStyle(
                        color: AppColors.purpleLabel,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: AppColors.textPrimaryAlt,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.teacher,
                    style: const TextStyle(
                      color: AppColors.neutralText5,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (item.timeRangeText.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.timeRangeText,
                      style: const TextStyle(
                        color: AppColors.textMuted8,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            _LiveNowButton(
              text: item.joinButtonLabel,
              enabled: item.canJoin,
              onTap: item.canJoin ? () => controller.joinLiveClass(item) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard();

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<UserProfileProvider>(context).profile;
    final hasVerifiedNumber = (profile?.mobile.trim() ?? '').isNotEmpty;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;
    final avatarSize = isCompact ? 48.0 : 54.0;
    final innerAvatarSize = isCompact ? 42.0 : 48.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 14 : 18),
      decoration: _cardDecoration(borderRadius: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.textPrimaryDeep,
                ),
                child: Center(
                  child: _ProfileAvatar(
                    imageUrl: profile?.profilePic ?? '',
                    size: innerAvatarSize,
                    iconSize: innerAvatarSize * 0.58,
                    borderWidth: 0,
                    backgroundColor: AppColors.transparent,
                  ),
                ),
              ),
              Positioned(
                right: -3,
                bottom: -3,
                child: GestureDetector(
                  onTap: () => Get.to(() => const EditProfileViews()),
                  child: Container(
                    width: 19,
                    height: 19,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.warning3,
                      border: Border.all(color: AppColors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: AppColors.warningTextDark,
                      size: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        profile?.name ?? 'Student',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: isCompact ? 15 : 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('👋', style: TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _ProfileChip(
                      label: 'Class ${profile?.userClass ?? '-'}',
                      background: AppColors.primaryLight,
                      textColor: AppColors.primaryBright,
                    ),
                    _ProfileChip(
                      label: _educationBoardLabel(
                        profile?.educationBoard,
                      ).toUpperCase(),
                      background: AppColors.boardBackground,
                      textColor: AppColors.boardText,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _ProfilePhoneRow(
                  hasVerifiedNumber: hasVerifiedNumber,
                  mobile: profile?.mobile ?? '',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatsCard extends GetView<DashboardTabbarController> {
  const _ProfileStatsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(borderRadius: 24),
      child: Obx(() {
        final xpSummary = controller.userXpSummary.value;
        final weakAreas = controller.weakAreasSummary.value;
        return Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Get.to(() => const DailyRewardsViews()),
                child: _ProfileStatTile(
                  icon: Icons.bolt_rounded,
                  iconColor: AppColors.purpleDark2,
                  value: xpSummary.xpText,
                  label: 'Total XP',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ProfileStatTile(
                icon: Icons.local_fire_department_rounded,
                iconColor: AppColors.warningText,
                value: xpSummary.profileStreakText,
                label: 'Streak',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ProfileStatTile(
                icon: Icons.track_changes_rounded,
                iconColor: const Color(0xFFE0433D),
                value: weakAreas.hasAttempts
                    ? weakAreas.overallAccuracyLabel
                    : '-',
                label: 'Accuracy',
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// Phone number row that mirrors the compact profile card design: a
/// verified pill when the number is confirmed, or a distinct amber
/// "unverified" pill with a tappable "Verify" action otherwise, so an
/// unverified account visually stands apart rather than blending in.
class _ProfilePhoneRow extends StatelessWidget {
  const _ProfilePhoneRow({
    required this.hasVerifiedNumber,
    required this.mobile,
  });

  final bool hasVerifiedNumber;
  final String mobile;

  String get _displayNumber {
    final trimmed = mobile.trim();
    if (trimmed.startsWith('+91')) {
      return trimmed;
    }
    if (trimmed.startsWith('91') && trimmed.length > 10) {
      return '+$trimmed';
    }
    return '+91 $trimmed';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => const EditProfileViews()),
      child: Row(
        children: [
          const Icon(
            Icons.phone_rounded,
            color: AppColors.textMuted2,
            size: 15,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              hasVerifiedNumber ? _displayNumber : 'Add mobile number',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted2,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (hasVerifiedNumber)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F9EF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF12B76A),
                    size: 13,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Verified',
                    style: TextStyle(
                      color: Color(0xFF12B76A),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0DA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Verify',
                style: TextStyle(
                  color: AppColors.warningTextDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({
    required this.label,
    required this.background,
    required this.textColor,
  });

  final String label;
  final Color background;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ProfileStatTile extends StatelessWidget {
  const _ProfileStatTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.neutralSurface2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.neutralText8,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionBanner extends StatelessWidget {
  const _SubscriptionBanner();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.to(() => const SubscriptionViews()),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [AppColors.purpleDark2, AppColors.primaryBright],
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Pro Subscription',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'FREE PLAN',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Unlock all mocks & 24/7 AI tutor',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Upgrade',
                style: TextStyle(
                  color: AppColors.purpleDark2,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({required this.item});

  final ProfileMenuData item;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardTabbarController>();

    return InkWell(
      onTap: () {
        if (item.title == 'Terms of Service') {
          Get.to(
            () => const _ProfilePolicyScreen(
              title: 'Terms of Service',
              sections: _termsOfServiceSections,
            ),
          );
          return;
        }

        if (item.title == 'Privacy Shield') {
          Get.to(
            () => const _ProfilePolicyScreen(
              title: 'Privacy Shield',
              sections: _privacyShieldSections,
            ),
          );
          return;
        }

        if (item.title == 'Update App') {
          AppUpdateService.instance.openPlayStore();
          return;
        }

        if (item.title == 'Query') {
          Get.to(() => const _QueryScreen());
          return;
        }

        controller.handleProfileMenuTap(item, context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.profileMenuBorder),
          ),
        ),
        child: Row(
          children: [
            Icon(item.icon, color: item.color, size: 26),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  color: item.color == AppColors.destructive
                      ? AppColors.destructive
                      : AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: item.color == AppColors.destructive
                  ? AppColors.neutralText11
                  : AppColors.neutralText10,
              size: 30,
            ),
          ],
        ),
      ),
    );
  }
}

/// Options a student can raise from the Profile tab: a product suggestion,
/// a direct contact channel, or a feature/content request.
class _QueryOptionData {
  const _QueryOptionData({
    required this.type,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final UserQueryType type;
  final String subtitle;
  final IconData icon;
  final Color color;

  String get title => type.label;
}

const List<_QueryOptionData> _queryOptions = [
  _QueryOptionData(
    type: UserQueryType.suggestion,
    subtitle: 'Tell us what could make the app better.',
    icon: Icons.lightbulb_outline_rounded,
    color: Color(0xFFB8860B),
  ),
  _QueryOptionData(
    type: UserQueryType.contact,
    subtitle: 'Reach our support team directly.',
    icon: Icons.support_agent_rounded,
    color: Color(0xFF1671D9),
  ),
  _QueryOptionData(
    type: UserQueryType.request,
    subtitle: 'Ask for a feature, subject or content.',
    icon: Icons.assignment_outlined,
    color: Color(0xFF19945F),
  ),
];

/// Accent of the Contact Us screen — its button, and the focus ring on its
/// message box. The other Query screens take theirs from the option tapped.
const Color _contactAccent = Color(0xFF1671D9);

/// WhatsApp brand green, used for its tile's mark and tinted circle.
const Color _whatsappGreen = Color(0xFF25D366);

const String _supportEmail = 'support@pixelnx.com';
const String _supportPhone = '+91 8989977272';

/// Opens a chat with support in WhatsApp.
///
/// `wa.me` needs the number as digits only, country code included and no `+`.
/// It resolves in the WhatsApp app when installed and falls back to WhatsApp
/// Web in a browser otherwise, so it works either way — hence
/// `externalApplication` rather than an in-app webview.
Future<void> _openWhatsApp() async {
  final digits = _supportPhone.replaceAll(RegExp(r'\D'), '');
  final uri = Uri.parse('https://wa.me/$digits');
  try {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (launched) return;
  } catch (_) {
    // Falls through to the message below.
  }
  Get.snackbar(
    'WhatsApp',
    'Could not open WhatsApp. You can message us on $_supportPhone.',
    snackPosition: SnackPosition.BOTTOM,
  );
}

/// Message box shared by every Query form.
///
/// The fill used to be `scaffoldBackground`, which is pure white, on a white
/// card and with no border — so the field was invisible until you happened to
/// tap it. It now sits on a tinted fill inside a visible outline that picks up
/// the screen's own accent colour while focused.
InputDecoration _queryFieldDecoration({
  required String hintText,
  required Color accent,
}) {
  OutlineInputBorder outline(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(
      color: AppColors.textMuted8,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    filled: true,
    fillColor: AppColors.neutralSurface2,
    border: outline(AppColors.headerBorder, 1.2),
    enabledBorder: outline(AppColors.headerBorder, 1.2),
    focusedBorder: outline(accent, 1.6),
    contentPadding: const EdgeInsets.all(14),
    counterStyle: const TextStyle(
      color: AppColors.textMuted8,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    ),
  );
}

/// Shared header for every Query screen, so the back button, title and the
/// slot opposite it stay identical across them.
class _QueryTopBar extends StatelessWidget {
  const _QueryTopBar({required this.title, this.trailing});

  final String title;

  /// Sits opposite the back button. The slot is reserved whether or not it is
  /// filled, so the title stays optically centred either way.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.headerBorder)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textBlueDark,
              size: 22,
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textBlueDark,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(width: 48, child: trailing),
        ],
      ),
    );
  }
}

/// Opens the student's own message history.
class _MyQueriesButton extends StatelessWidget {
  const _MyQueriesButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'My Queries',
      padding: EdgeInsets.zero,
      onPressed: () => Get.to(() => const _MyQueriesScreen()),
      icon: const Icon(
        Icons.history_rounded,
        color: AppColors.textBlueDark,
        size: 24,
      ),
    );
  }
}

class _QueryScreen extends StatelessWidget {
  const _QueryScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            const _QueryTopBar(title: 'Query', trailing: _MyQueriesButton()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cardShadow.withValues(alpha: 0.20),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: _queryOptions
                          .map((option) => _QueryOptionTile(option: option))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueryOptionTile extends StatelessWidget {
  const _QueryOptionTile({required this.option});

  final _QueryOptionData option;

  bool get _isLast => option.type == _queryOptions.last.type;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (option.type == UserQueryType.contact) {
          Get.to(() => const _ContactUsScreen());
          return;
        }
        Get.to(() => _QueryFormScreen(option: option));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          border: _isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: AppColors.profileMenuBorder),
                ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: option.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(option.icon, color: option.color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    option.subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted8,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.neutralText10,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}

/// Sends a Query message and tells the student how it went.
///
/// Returns true once the message is with the server, which both query forms
/// take as their cue to close. A repeat of the same message inside ten
/// minutes also answers success, so a double tap looks no different to the
/// student and nothing is sent twice.
///
/// Failures are reported in the server's own words — it is what explains the
/// 30-second gap between messages, the ten-a-day cap and the length limits,
/// and those explanations are written for the student.
Future<bool> _submitUserQuery({
  required UserQueryType type,
  required String message,
}) async {
  final validationError = UserQueryRepository.validationError(message, type);
  if (validationError != null) {
    Get.snackbar(
      type.label,
      validationError,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.white,
      colorText: AppColors.textPrimaryDeep,
      margin: const EdgeInsets.all(14),
    );
    return false;
  }

  final response = await UserQueryRepository.submit(
    type: type,
    message: message,
  );

  if (!response.success) {
    Get.snackbar(
      type.label,
      response.message.isNotEmpty
          ? response.message
          : 'Your message could not be sent. Please try again.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.destructive,
      colorText: AppColors.white,
      margin: const EdgeInsets.all(14),
      duration: const Duration(seconds: 4),
    );
    return false;
  }

  Get.snackbar(
    'Thank you!',
    response.message.isNotEmpty
        ? response.message
        : 'Your message has been sent.',
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: AppColors.white,
    colorText: AppColors.textPrimaryDeep,
    margin: const EdgeInsets.all(14),
    duration: const Duration(seconds: 4),
  );
  return true;
}

/// Lands the student on their message history once a query is sent.
///
/// The form and the Query menu are dropped on the way, so the message they
/// just sent is what they see, and one back press from here returns to the
/// Profile tab rather than walking them back through the form they have
/// already submitted.
void _openMyQueriesAfterSubmit() {
  Get.offUntil(
    GetPageRoute<void>(page: () => const _MyQueriesScreen()),
    (route) => route.isFirst,
  );
}

/// Generic message form used by the Suggestion and Request options.
class _QueryFormScreen extends StatefulWidget {
  const _QueryFormScreen({required this.option});

  final _QueryOptionData option;

  @override
  State<_QueryFormScreen> createState() => _QueryFormScreenState();
}

class _QueryFormScreenState extends State<_QueryFormScreen> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final sent = await _submitUserQuery(
      type: widget.option.type,
      message: _controller.text,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (sent) {
      _openMyQueriesAfterSubmit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            _QueryTopBar(
              title: widget.option.title,
              trailing: const _MyQueriesButton(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cardShadow.withValues(alpha: 0.20),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.option.subtitle,
                          style: const TextStyle(
                            color: AppColors.textMuted8,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _controller,
                          maxLines: 6,
                          minLines: 6,
                          // Stops the student writing past what the API
                          // accepts, and shows them how much room is left.
                          maxLength: UserQueryRepository.maxMessageLength,
                          cursorColor: widget.option.color,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                          decoration: _queryFieldDecoration(
                            hintText:
                                'Type your ${widget.option.title.toLowerCase()} here...',
                            accent: widget.option.color,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.option.color,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Submit',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dedicated Contact Us screen: direct email/phone plus a message form.
class _ContactUsScreen extends StatefulWidget {
  const _ContactUsScreen();

  @override
  State<_ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<_ContactUsScreen> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final sent = await _submitUserQuery(
      type: UserQueryType.contact,
      message: _controller.text,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (sent) {
      _openMyQueriesAfterSubmit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            const _QueryTopBar(
              title: 'Contact Us',
              trailing: _MyQueriesButton(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cardShadow.withValues(alpha: 0.20),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _ContactActionTile(
                          icon: const Icon(
                            Icons.email_outlined,
                            color: _contactAccent,
                            size: 22,
                          ),
                          color: _contactAccent,
                          title: 'Email us',
                          subtitle: _supportEmail,
                          onTap: () => launchUrl(
                            Uri(scheme: 'mailto', path: _supportEmail),
                          ),
                        ),
                        _ContactActionTile(
                          // Material has no WhatsApp glyph, so the brand mark
                          // ships as an asset.
                          icon: SvgPicture.asset(
                            'assets/icon/whatsapp.svg',
                            width: 24,
                            height: 24,
                            colorFilter: const ColorFilter.mode(
                              _whatsappGreen,
                              BlendMode.srcIn,
                            ),
                          ),
                          color: _whatsappGreen,
                          title: 'WhatsApp us',
                          subtitle: _supportPhone,
                          isLast: true,
                          onTap: _openWhatsApp,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cardShadow.withValues(alpha: 0.20),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Or send us a message',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _controller,
                          maxLines: 6,
                          minLines: 6,
                          maxLength: UserQueryRepository.maxMessageLength,
                          cursorColor: _contactAccent,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                          decoration: _queryFieldDecoration(
                            hintText: 'Type your message here...',
                            accent: _contactAccent,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _contactAccent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Submit',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactActionTile extends StatelessWidget {
  const _ContactActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLast = false,
  });

  /// Drawn inside the tinted circle. A widget rather than an `IconData` so
  /// brand marks that Material has no glyph for (WhatsApp) fit here too.
  final Widget icon;

  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: AppColors.profileMenuBorder),
                ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: icon,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted8,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.neutralText10,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}

/// Everything the student has sent from the Query screen, newest first, with
/// whether an admin has dealt with it yet.
class _MyQueriesScreen extends StatefulWidget {
  const _MyQueriesScreen();

  @override
  State<_MyQueriesScreen> createState() => _MyQueriesScreenState();
}

class _MyQueriesScreenState extends State<_MyQueriesScreen> {
  static const int _pageSize = 20;

  final ScrollController _scrollController = ScrollController();
  final List<UserQueryItem> _queries = [];

  /// null means every type — the "All" filter.
  UserQueryType? _filter;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _page = 1;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoading || _isLoadingMore) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final response = await UserQueryRepository.fetchMyQueries(
      type: _filter,
      page: 1,
      limit: _pageSize,
    );
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _page = 1;
      if (response.success && response.data != null) {
        final page = response.data!;
        _queries
          ..clear()
          ..addAll(page.queries);
        _hasMore = page.hasMore;
      } else {
        _queries.clear();
        _hasMore = false;
        _error = response.message;
      }
    });
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);

    final response = await UserQueryRepository.fetchMyQueries(
      type: _filter,
      page: _page + 1,
      limit: _pageSize,
    );
    if (!mounted) return;

    setState(() {
      _isLoadingMore = false;
      if (response.success && response.data != null) {
        final page = response.data!;
        _queries.addAll(page.queries);
        _page = page.page;
        _hasMore = page.hasMore;
      } else {
        // Leave what is already listed and stop paging rather than replacing
        // the list with an error the student cannot act on.
        _hasMore = false;
      }
    });
  }

  void _changeFilter(UserQueryType? type) {
    if (_filter == type) {
      return;
    }
    setState(() => _filter = type);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Tinted rather than the usual white: the cards are white, so on a
      // white page they ran together into one block and the student could not
      // tell where one message ended and the next began.
      backgroundColor: AppColors.neutralSurface,
      body: SafeArea(
        child: Column(
          children: [
            const _QueryTopBar(title: 'My Queries'),
            _MyQueriesFilterBar(selected: _filter, onChanged: _changeFilter),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Always a scrollable, so pull-to-refresh still works on the empty and
    // error states.
    return ListView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        if (_error.isNotEmpty)
          _MyQueriesStateCard(
            icon: Icons.wifi_off_rounded,
            title: 'Unable to load your queries',
            message: _error,
            onRetry: _load,
          )
        else if (_queries.isEmpty)
          _MyQueriesStateCard(
            icon: Icons.forum_outlined,
            title: _filter == null
                ? 'No messages yet'
                : 'No ${_filter!.label.toLowerCase()} yet',
            message:
                'Anything you send from the Query screen will show up here, '
                'along with whether our team has answered it.',
          )
        else ...[
          for (final query in _queries)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              // Under a type filter every card is that type, so repeating it
              // on each one says nothing — the date leads instead.
              child: _MyQueryCard(query: query, showTypeLabel: _filter == null),
            ),
          if (_isLoadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _MyQueriesFilterBar extends StatelessWidget {
  const _MyQueriesFilterBar({required this.selected, required this.onChanged});

  final UserQueryType? selected;
  final ValueChanged<UserQueryType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.headerBorder)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _MyQueriesFilterChip(
              label: 'All',
              isSelected: selected == null,
              color: AppColors.textBlueDark,
              onTap: () => onChanged(null),
            ),
            for (final option in _queryOptions)
              _MyQueriesFilterChip(
                label: option.title,
                isSelected: selected == option.type,
                color: option.color,
                onTap: () => onChanged(option.type),
              ),
          ],
        ),
      ),
    );
  }
}

class _MyQueriesFilterChip extends StatelessWidget {
  const _MyQueriesFilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? color : AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : AppColors.headerBorder,
              width: 1.4,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.white : AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _MyQueryCard extends StatelessWidget {
  const _MyQueryCard({required this.query, this.showTypeLabel = true});

  final UserQueryItem query;

  /// Whether to name the query's type on the card. False under a type filter,
  /// where the chip above already says it and every card would repeat it.
  final bool showTypeLabel;

  /// The look of the option this message was sent under. Falls back to the
  /// Suggestion palette for a type this build does not recognise, so an
  /// unknown type still renders as a normal card.
  _QueryOptionData get _option {
    final type = query.option;
    for (final option in _queryOptions) {
      if (option.type == type) {
        return option;
      }
    }
    return _queryOptions.first;
  }

  @override
  Widget build(BuildContext context) {
    final option = _option;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        // Outlined as well as shadowed: the shadow alone disappears against a
        // pale background, and the edge is what separates one message card
        // from the next.
        border: Border.all(color: AppColors.headerBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: option.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(option.icon, color: option.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: showTypeLabel
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            query.displayLabel,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatQueryDate(query.createdAt),
                            style: const TextStyle(
                              color: AppColors.textMuted8,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        _formatQueryDate(query.createdAt),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              _MyQueryStatusPill(isResolved: query.isResolved),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            query.message,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          if (query.isResolved && query.resolvedAt != null) ...[
            const SizedBox(height: 10),
            Text(
              'Resolved on ${_formatQueryDate(query.resolvedAt)}',
              style: const TextStyle(
                color: AppColors.success,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MyQueryStatusPill extends StatelessWidget {
  const _MyQueryStatusPill({required this.isResolved});

  final bool isResolved;

  @override
  Widget build(BuildContext context) {
    final color = isResolved ? AppColors.success : const Color(0xFFF1670C);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isResolved ? 'Resolved' : 'Open',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MyQueriesStateCard extends StatelessWidget {
  const _MyQueriesStateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(icon, size: 46, color: AppColors.neutralText10),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted8,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.6,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}

/// `21 Sep 2026 · 2:42 PM`, or an empty string when the server sent no date.
String _formatQueryDate(DateTime? value) {
  if (value == null) {
    return '';
  }
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = value.toLocal();
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final meridiem = local.hour < 12 ? 'AM' : 'PM';
  return '${local.day} ${months[local.month - 1]} ${local.year} · '
      '$hour12:$minute $meridiem';
}

class _ProfilePolicyScreen extends StatelessWidget {
  const _ProfilePolicyScreen({required this.title, required this.sections});

  final String title;
  final List<_PolicySectionData> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(
                  bottom: BorderSide(color: AppColors.headerBorder),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: Get.back,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textBlueDark,
                      size: 22,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textBlueDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cardShadow.withValues(alpha: 0.20),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (
                          var index = 0;
                          index < sections.length;
                          index++
                        ) ...[
                          _PolicySection(section: sections[index]),
                          if (index != sections.length - 1)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 18),
                              child: Divider(
                                color: AppColors.profileMenuBorder,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.section});

  final _PolicySectionData section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                section.icon,
                color: AppColors.primaryBright,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                section.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          section.body,
          style: const TextStyle(
            color: AppColors.neutralText5,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

class _PolicySectionData {
  const _PolicySectionData({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;
}

const _termsOfServiceSections = [
  _PolicySectionData(
    title: 'Learning Account',
    body:
        'EduPath Learning is built for student learning, practice, live classes, homework, notes, e-books, attendance, XP and leaderboard features. Use your own account only, keep your login details private, and make sure profile details such as class, board and school information are accurate.',
    icon: Icons.person_outline_rounded,
  ),
  _PolicySectionData(
    title: 'Classroom Conduct',
    body:
        'Join live classes on time, use respectful language with teachers and classmates, and do not share Meet links, lesson content, homework answers or private class material outside the app. Misuse of chat, doubt solving, calls, uploads or downloads may lead to restricted access.',
    icon: Icons.school_outlined,
  ),
  _PolicySectionData(
    title: 'Study Content',
    body:
        'Videos, PDFs, notes, quizzes, mock tests, e-books and worksheets are provided for personal study. You may save available files for offline learning inside the app, but you should not copy, resell, publish or redistribute the material without permission.',
    icon: Icons.menu_book_outlined,
  ),
  _PolicySectionData(
    title: 'Progress And Results',
    body:
        'Quiz scores, mock test attempts, lesson progress, XP, streaks, attendance and leaderboard rankings are shown to help you improve. Results depend on submitted answers, attendance records and teacher/admin updates, so occasional corrections or sync delays may happen.',
    icon: Icons.query_stats_rounded,
  ),
  _PolicySectionData(
    title: 'Safe Use',
    body:
        'Keep the app updated, use a stable internet connection for tests and live classes, and report any incorrect content or technical issue to support. The app can update features, learning rules or access controls to keep the platform reliable and safe.',
    icon: Icons.verified_user_outlined,
  ),
];

const _privacyShieldSections = [
  _PolicySectionData(
    title: 'Information We Use',
    body:
        'The app may use your name, mobile/email login details, class, board, profile photo, selected subjects, lesson progress, quiz attempts, homework submissions, attendance, XP, streaks, downloads and live class participation to personalize your learning experience.',
    icon: Icons.badge_outlined,
  ),
  _PolicySectionData(
    title: 'Why It Is Needed',
    body:
        'Your data helps show the right subjects, unlock chapters, save progress, display marks, manage attendance, recommend practice, support teacher doubt solving, maintain downloads, and keep your account secure across app sessions.',
    icon: Icons.tune_rounded,
  ),
  _PolicySectionData(
    title: 'Student Safety',
    body:
        'Student information is used only for learning, support, classroom management and platform safety. We avoid asking for unnecessary personal details, and sensitive actions such as profile updates, sign out and account deletion stay under account control.',
    icon: Icons.shield_outlined,
  ),
  _PolicySectionData(
    title: 'Storage And Downloads',
    body:
        'Offline PDFs and learning files are saved on your device for study access. You can remove individual downloads or clear all downloads from the Downloads screen. Deleting downloads removes local files but does not erase your account progress.',
    icon: Icons.download_done_outlined,
  ),
  _PolicySectionData(
    title: 'Your Choices',
    body:
        'You can update profile details, sign out, clear downloads, or request account deletion from the profile area. If something looks wrong in your profile, attendance, progress or results, contact your school or app support for correction.',
    icon: Icons.settings_outlined,
  ),
];

class _AvatarStack extends StatefulWidget {
  const _AvatarStack({required this.summary});

  final LeaderboardStripData summary;

  @override
  State<_AvatarStack> createState() => _AvatarStackState();
}

class _AvatarStackState extends State<_AvatarStack> {
  @override
  void initState() {
    super.initState();
    _headerIntroDone.addListener(_onHeaderIntroChanged);
  }

  @override
  void dispose() {
    _headerIntroDone.removeListener(_onHeaderIntroChanged);
    super.dispose();
  }

  void _onHeaderIntroChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final students = summary.topStudents;
    final showRemaining = summary.remainingStudents > 0;
    final width = students.isEmpty
        ? 0.0
        : ((students.length - 1) * 20 + 34 + (showRemaining ? 20 : 0))
              .toDouble();
    final animate = _headerIntroDone.value;

    return SizedBox(
      width: width,
      height: 34,
      child: Stack(
        children: [
          for (var index = 0; index < students.length; index++)
            Positioned(
              left: index * 20,
              child: _StaggeredSlideIn(
                animate: animate,
                delay: Duration(seconds: index),
                child: _LeaderboardStripAvatar(student: students[index]),
              ),
            ),
          if (showRemaining)
            Positioned(
              left: students.length * 20,
              child: _StaggeredSlideIn(
                animate: animate,
                delay: Duration(seconds: students.length),
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.avatarLight,
                  child: Text(
                    summary.remainingText,
                    style: const TextStyle(
                      color: AppColors.neutralText9,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Slides [child] up from below with a fade-in, starting after [delay]
/// once [animate] turns true. Used to stagger the leaderboard avatars
/// in one by one.
class _StaggeredSlideIn extends StatefulWidget {
  const _StaggeredSlideIn({
    required this.animate,
    required this.delay,
    required this.child,
  });

  final bool animate;
  final Duration delay;
  final Widget child;

  @override
  State<_StaggeredSlideIn> createState() => _StaggeredSlideInState();
}

class _StaggeredSlideInState extends State<_StaggeredSlideIn> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _maybeStart();
  }

  @override
  void didUpdateWidget(_StaggeredSlideIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeStart();
  }

  void _maybeStart() {
    if (_started || !widget.animate) return;
    _started = true;
    Future.delayed(widget.delay, () {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.animate && _started;
    return AnimatedSlide(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      offset: visible ? Offset.zero : const Offset(1.4, 0),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOut,
        opacity: visible ? 1 : 0,
        child: widget.child,
      ),
    );
  }
}

class _LeaderboardStripAvatar extends StatelessWidget {
  const _LeaderboardStripAvatar({required this.student});

  final LeaderboardStripStudent student;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 17,
      backgroundColor: student.color,
      child: ClipOval(
        child: student.profilePic.trim().isNotEmpty
            ? Image.network(
                student.profilePic,
                width: 34,
                height: 34,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _LeaderboardStripInitials(initials: student.initials),
              )
            : _LeaderboardStripInitials(initials: student.initials),
      ),
    );
  }
}

class _LeaderboardStripInitials extends StatelessWidget {
  const _LeaderboardStripInitials({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  const _BadgeItem({
    required this.label,
    required this.color,
    required this.icon,
    this.textColor = AppColors.textDark,
  });

  final String label;
  final Color color;
  final IconData icon;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 34,
          backgroundColor: color,
          child: Icon(icon, color: AppColors.white, size: 25),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 84,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MockStatusBadge extends StatelessWidget {
  const _MockStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final key = status.toLowerCase();
    Color background;
    Color foreground;
    String emoji;

    if (key.contains('miss') || key.contains('end')) {
      background = const Color(0xFFFDECEC);
      foreground = const Color(0xFFE5484D);
      emoji = '😞';
    } else if (key.contains('live')) {
      background = const Color(0xFFE3F6EC);
      foreground = const Color(0xFF17935F);
      emoji = '🔴';
    } else if (key.contains('attempt')) {
      background = const Color(0xFFEDEBFF);
      foreground = const Color(0xFF5A3FE0);
      emoji = '✅';
    } else {
      background = const Color(0xFFEAF2FF);
      foreground = const Color(0xFF2F6FE0);
      emoji = '⏳';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectTag extends StatelessWidget {
  const _SubjectTag({
    required this.label,
    required this.background,
    required this.textColor,
  });

  final String label;
  final Color background;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LiveNowButton extends StatelessWidget {
  const _LiveNowButton({required this.text, required this.enabled, this.onTap});

  final String text;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = enabled ? AppColors.white : AppColors.neutralText7;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : AppColors.neutralSurface3,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                color: foreground,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (enabled) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.white,
                size: 22,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration({double borderRadius = 26}) {
  return BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(color: AppColors.cardBorder),
    boxShadow: [
      BoxShadow(
        color: AppColors.cardShadow.withValues(alpha: 0.24),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

Color _weakAreaAccent(String subjectName) {
  final name = subjectName.toLowerCase();
  if (name.contains('math')) {
    return const Color(0xFF1671D9);
  }
  if (name.contains('physics') || name.contains('science')) {
    return const Color(0xFFE45656);
  }
  if (name.contains('computer')) {
    return const Color(0xFF4A4FD9);
  }
  if (name.contains('english')) {
    return const Color(0xFF19945F);
  }
  return const Color(0xFF1671D9);
}

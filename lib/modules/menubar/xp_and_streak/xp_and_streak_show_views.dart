import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/xp_config_data.dart';
import '../../../core/service/api_service.dart';

class XpAndStreakShowViews extends StatefulWidget {
  const XpAndStreakShowViews({super.key});

  @override
  State<XpAndStreakShowViews> createState() => _XpAndStreakShowViewsState();
}

class _XpAndStreakShowViewsState extends State<XpAndStreakShowViews> {
  bool _isLoading = true;
  String _errorMessage = '';
  XpConfigData? _config;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.USER_XP,
      showLoader: false,
      fromJson: (json) => json,
    );

    if (!mounted) {
      return;
    }

    if (!response.success || response.data is! Map<String, dynamic>) {
      setState(() {
        _isLoading = false;
        _errorMessage = response.message;
      });
      return;
    }

    final body = response.data as Map<String, dynamic>;
    final data = body['data'];
    final config = data is Map<String, dynamic> ? data['config'] : null;
    if (config is! Map<String, dynamic>) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'XP config data not found.';
      });
      return;
    }

    setState(() {
      _isLoading = false;
      _config = XpConfigData.fromApi(config);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF075EAE),
            size: 20,
          ),
        ),
        title: const Text(
          'XP & Streak Settings',
          style: TextStyle(
            color: Color(0xFF075EAE),
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE6EAF2)),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadConfig,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    const _InfoBanner(),
                    const SizedBox(height: 18),
                    if (_isLoading)
                      const SizedBox(
                        height: 360,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_errorMessage.isNotEmpty)
                      _XpStateCard(message: _errorMessage, onRetry: _loadConfig)
                    else
                      _XpConfigContent(config: _config ?? const XpConfigData()),
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

class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFDCEBFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF075EAE), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'You can review the current XP configuration. Awards are limited to one per eligible activity, based on backend rules.',
              style: TextStyle(
                color: Color(0xFF476178),
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _XpConfigContent extends StatelessWidget {
  const _XpConfigContent({required this.config});

  final XpConfigData config;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.calendar_today_outlined,
          title: 'Daily activities',
          subtitle: 'XP earned per calendar day',
        ),
        const SizedBox(height: 10),
        _XpSectionCard(
          items: [
            _XpSettingItem(
              title: 'Daily login',
              subtitle: 'XP for the first login each day.',
              value: config.dailyLoginXp,
            ),
            _XpSettingItem(
              title: 'Daily quiz attempt',
              subtitle: 'XP for submitting today\'s daily quiz.',
              value: config.dailyQuizAttemptXp,
            ),
            _XpSettingItem(
              title: 'Daily quiz pass bonus',
              subtitle: 'Extra XP when the daily quiz is passed.',
              value: config.dailyQuizPassBonusXp,
            ),
            _XpSettingItem(
              title: 'Lesson complete',
              subtitle: 'XP for the first lesson completed each day.',
              value: config.lessonCompleteXp,
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SectionHeader(
          icon: Icons.rocket_launch_outlined,
          title: 'Normal activities',
          subtitle: 'XP rewards for quizzes, tests and homework',
        ),
        const SizedBox(height: 10),
        _XpSectionCard(
          items: [
            _XpSettingItem(
              title: 'Regular quiz attempt',
              subtitle: 'XP on the first attempt only.',
              value: config.regularQuizAttemptXp,
            ),
            _XpSettingItem(
              title: 'Regular quiz pass bonus',
              subtitle: 'Extra XP when the first attempt passes.',
              value: config.regularQuizPassBonusXp,
            ),
            _XpSettingItem(
              title: 'Mock test attempt',
              subtitle: 'XP for submitting a mock test.',
              value: config.mockTestAttemptXp,
            ),
            _XpSettingItem(
              title: 'Mock test pass bonus',
              subtitle: 'Extra XP when a mock test is passed.',
              value: config.mockTestPassBonusXp,
            ),
            _XpSettingItem(
              title: 'Homework submit',
              subtitle: 'XP for the first homework submission.',
              value: config.homeworkSubmitXp,
            ),
            _XpSettingItem(
              title: 'Good marks bonus',
              subtitle: 'Extra XP when homework meets the threshold.',
              value: config.homeworkGoodMarksBonusXp,
            ),
            _XpSettingItem(
              title: 'Good-marks threshold',
              subtitle: 'Percentage cut-off for homework bonus.',
              value: config.homeworkGoodMarksThreshold,
              suffix: '%',
              highlight: true,
              showOffWhenZero: false,
            ),
          ],
        ),
        const SizedBox(height: 18),
        _StreakActivityCard(activity: config.streakActivity),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF075EAE), size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1D2231),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF8B93A5),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _XpSectionCard extends StatelessWidget {
  const _XpSectionCard({required this.items});

  final List<_XpSettingItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCBD4E5).withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          return Column(
            children: [
              items[index],
              if (index != items.length - 1)
                const Divider(
                  height: 1,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Color(0xFFF0F2F6),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _XpSettingItem extends StatelessWidget {
  const _XpSettingItem({
    required this.title,
    required this.subtitle,
    required this.value,
    this.suffix = ' XP',
    this.highlight = false,
    this.showOffWhenZero = true,
  });

  final String title;
  final String subtitle;
  final int value;
  final String suffix;
  final bool highlight;
  final bool showOffWhenZero;

  @override
  Widget build(BuildContext context) {
    final disabled = showOffWhenZero && value == 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1D2231),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6F7788),
                    fontSize: 10,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            constraints: const BoxConstraints(minWidth: 62),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: highlight
                  ? const Color(0xFFFFE3CE)
                  : disabled
                  ? const Color(0xFFF0F2F6)
                  : const Color(0xFFEFF3F8),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              disabled ? 'Off' : '$value$suffix',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: highlight
                    ? const Color(0xFFC05716)
                    : disabled
                    ? const Color(0xFF8A93A3)
                    : const Color(0xFF075EAE),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakActivityCard extends StatelessWidget {
  const _StreakActivityCard({required this.activity});

  final String activity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD37B)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: Color(0xFFF59E0B),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Streak activity',
                  style: TextStyle(
                    color: Color(0xFF1D2231),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _streakActivityLabel(activity),
                  style: const TextStyle(
                    color: Color(0xFF8A5A00),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

class _XpStateCard extends StatelessWidget {
  const _XpStateCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFB42318),
            size: 36,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1D2231),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

String _streakActivityLabel(String value) {
  switch (value) {
    case 'daily-login':
      return 'Daily login keeps the streak active';
    case 'daily-quiz-attempt':
      return 'Daily quiz attempt keeps the streak active';
    case 'lesson-complete':
      return 'Lesson completion keeps the streak active';
    case 'regular-quiz-attempt':
      return 'Regular quiz attempt keeps the streak active';
    default:
      return value.trim().isEmpty ? 'Not configured' : value;
  }
}

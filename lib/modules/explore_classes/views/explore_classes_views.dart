import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ExploreClassesViews extends StatelessWidget {
  const ExploreClassesViews({super.key});

  static const List<_ExploreClassItem> _classes = [
    _ExploreClassItem(
      level: 'Elementary',
      title: 'Class 5',
      description: 'Foundation of core concepts,',
      tagColor: Color(0xFF6268F4),
      cardColor: Colors.white,
      borderColor: Color(0xFFD9DBF8),
      textColor: Color(0xFF1A1D29),
      descriptionColor: Color(0xFF3C4256),
      actionLabel: 'Locked',
      actionBackground: Color(0xFFF0F2F6),
      actionForeground: Color(0xFF2A3144),
    ),
    _ExploreClassItem(
      level: 'Middle School',
      title: 'Class 6',
      description: 'Exploring nature and math.',
      tagColor: Color(0xFFFFB022),
      cardColor: Colors.white,
      borderColor: Color(0xFFD9DBF8),
      textColor: Color(0xFF1A1D29),
      descriptionColor: Color(0xFF3C4256),
      actionLabel: 'Locked',
      actionBackground: Color(0xFFF0F2F6),
      actionForeground: Color(0xFF2A3144),
    ),
    _ExploreClassItem(
      level: 'Middle School',
      title: 'Class 7',
      description: 'Developing analytical skills.',
      tagColor: Color(0xFF9B4CF7),
      cardColor: Colors.white,
      borderColor: Color(0xFFD9DBF8),
      textColor: Color(0xFF1A1D29),
      descriptionColor: Color(0xFF3C4256),
      actionLabel: 'Locked',
      actionBackground: Color(0xFFF0F2F6),
      actionForeground: Color(0xFF2A3144),
    ),
    _ExploreClassItem(
      level: 'Most Popular',
      title: 'Class 8',
      description:
          'Deep dive into Science, Literature,\nand Advanced Mathematics with AI-\nguided paths.',
      tagColor: Color(0xFF3F3FD2),
      cardColor: Colors.white,
      borderColor: Color(0xFFBCB9FF),
      textColor: Color(0xFF1A1D29),
      descriptionColor: Color(0xFF3C4256),
      actionLabel: 'Locked',
      actionBackground: Color(0xFFF0F2F6),
      actionForeground: Color(0xFF2A3144),
      isFeatured: true,
    ),
    _ExploreClassItem(
      level: 'High School Prep',
      title: 'Class 9',
      description: 'Focus on Biology and Research.',
      tagColor: Color(0xFFFFB022),
      cardColor: Colors.white,
      borderColor: Color(0xFFD9DBF8),
      textColor: Color(0xFF1A1D29),
      descriptionColor: Color(0xFF3C4256),
      actionLabel: 'Locked',
      actionBackground: Color(0xFFF0F2F6),
      actionForeground: Color(0xFF2A3144),
    ),
    _ExploreClassItem(
      level: 'Board Exams',
      title: 'Class 10',
      description: 'Comprehensive Boards preparation.',
      tagColor: Color(0xFF9B4CF7),
      cardColor: Colors.white,
      borderColor: Color(0xFFD9DBF8),
      textColor: Color(0xFF1A1D29),
      descriptionColor: Color(0xFF3C4256),
      actionLabel: 'Locked',
      actionBackground: Color(0xFFF0F2F6),
      actionForeground: Color(0xFF2A3144),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Row(
                children: [
                  InkWell(
                    onTap: Get.back,
                    borderRadius: BorderRadius.circular(18),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: Color(0xFF133B95),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Back',
                    style: TextStyle(
                      color: Color(0xFF12388F),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SearchBar(),
                    const SizedBox(height: 28),
                    const Text(
                      'Explore Classes',
                      style: TextStyle(
                        color: Color(0xFF1D212D),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Find your academic path and start your\njourney of discovery.',
                      style: TextStyle(
                        color: Color(0xFF2F3445),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 22),
                    ..._classes.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _ExploreClassCard(item: item),
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

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0F2F7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A74F7).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: Color(0xFF6B7085),
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Search your subjects or grade...',
              style: TextStyle(
                color: Color(0xFF757C91),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreClassCard extends StatelessWidget {
  const _ExploreClassCard({required this.item});

  final _ExploreClassItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        18,
        18,
        item.isFeatured ? 18 : 16,
      ),
      decoration: BoxDecoration(
        color: item.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: item.borderColor),
        boxShadow: item.isFeatured
            ? [
                BoxShadow(
                  color: const Color(0xFF7C76F4).withValues(alpha: 0.20),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF8D95C8).withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2430),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    size: 14,
                    color: Color(0xFFFFD66E),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'PRO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: item.tagColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.level,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F8),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE1E5EF)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 14,
                      color: Color(0xFF63697E),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Locked Content',
                      style: TextStyle(
                        color: Color(0xFF555B70),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                item.title,
                style: TextStyle(
                  color: item.textColor,
                  fontSize: item.isFeatured ? 19 : 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.description,
                style: TextStyle(
                  color: item.descriptionColor,
                  fontSize: item.isFeatured ? 14 : 13,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              _ActionButton(item: item),
              if (item.isFeatured) ...[
                const SizedBox(height: 22),
                const Center(child: _FeaturedScienceIllustration()),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.item});

  final _ExploreClassItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: item.isFeatured ? 190 : double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: item.actionBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            item.actionLabel,
            style: TextStyle(
              color: item.actionForeground,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          Icon(
            item.isFeatured
                ? Icons.play_circle_outline_rounded
                : Icons.arrow_forward_rounded,
            color: item.actionForeground,
            size: item.isFeatured ? 20 : 22,
          ),
        ],
      ),
    );
  }
}

class _FeaturedScienceIllustration extends StatelessWidget {
  const _FeaturedScienceIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 178,
      height: 178,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF201D4D),
            Color(0xFF121127),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F2A73).withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 16,
            left: 20,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.65),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 28,
            right: 28,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 18,
            right: 18,
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF0A091A),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const Center(
            child: Icon(
              Icons.science_outlined,
              size: 82,
              color: Color(0xFFE2E0FF),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreClassItem {
  const _ExploreClassItem({
    required this.level,
    required this.title,
    required this.description,
    required this.tagColor,
    required this.cardColor,
    required this.borderColor,
    required this.textColor,
    required this.descriptionColor,
    required this.actionLabel,
    required this.actionBackground,
    required this.actionForeground,
    this.isFeatured = false,
  });

  final String level;
  final String title;
  final String description;
  final Color tagColor;
  final Color cardColor;
  final Color borderColor;
  final Color textColor;
  final Color descriptionColor;
  final String actionLabel;
  final Color actionBackground;
  final Color actionForeground;
  final bool isFeatured;
}

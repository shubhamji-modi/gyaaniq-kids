import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PreviewResultViews extends StatefulWidget {
  const PreviewResultViews({super.key});

  @override
  State<PreviewResultViews> createState() => _PreviewResultViewsState();
}

class _PreviewResultViewsState extends State<PreviewResultViews> {
  int _selectedTabIndex = 0;

  static const List<String> _tabs = [
    'All',
    'Quizzes',
    'Mock Tests',
    'Monthly',
  ];

  static const List<_PreviewResultItem> _results = [
    _PreviewResultItem(
      title: 'Algebra Unit Test',
      date: 'Oct 12, 2023',
      questionCount: 25,
      score: 92,
      accent: Color(0xFF4A4FD9),
      icon: Icons.functions_rounded,
      iconBackground: Color(0xFFD9DBFF),
      actionLabel: 'View Analysis',
      category: 'Quizzes',
    ),
    _PreviewResultItem(
      title: 'Plant Cell Quiz',
      date: 'Oct 08, 2023',
      questionCount: 15,
      score: 78,
      accent: Color(0xFF9C6500),
      icon: Icons.biotech_outlined,
      iconBackground: Color(0xFFFFE9C7),
      actionLabel: 'Review Answers',
      category: 'Quizzes',
    ),
    _PreviewResultItem(
      title: 'Ancient Civilizations',
      date: 'Oct 05, 2023',
      questionCount: 40,
      score: 55,
      accent: Color(0xFF7C31D8),
      icon: Icons.account_balance_outlined,
      iconBackground: Color(0xFFEBD8FF),
      actionLabel: 'Retake Test',
      category: 'Mock Tests',
    ),
    _PreviewResultItem(
      title: 'Chemical Reactions',
      date: 'Sep 28, 2023',
      questionCount: 20,
      score: 90,
      accent: Color(0xFF4A4FD9),
      icon: Icons.science_outlined,
      iconBackground: Color(0xFFFFE8E8),
      actionLabel: 'View Analysis',
      category: 'Monthly',
    ),
  ];

  List<_PreviewResultItem> get _filteredResults {
    final selectedTab = _tabs[_selectedTabIndex];
    if (selectedTab == 'All') return _results;
    return _results.where((item) => item.category == selectedTab).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 5),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE8ECF5)),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: Get.back,
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFF143B8E),
                      size: 25,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Preview Result',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF143B8E),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 30,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          final isSelected = _selectedTabIndex == index;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTabIndex = index;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 21,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF4A4FD9)
                                    : const Color(0xFFE6E7EB),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _tabs[index],
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF4A4B5D),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          );
                        },
                        separatorBuilder: (_, index) =>
                            const SizedBox(width: 14),
                        itemCount: _tabs.length,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ..._filteredResults.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _ResultCard(item: item),
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

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.item});

  final _PreviewResultItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC9CAE8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCBD4ED).withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: item.iconBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.accent, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Color(0xFF1F2430),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${item.date} • ${item.questionCount} Questions',
                      style: const TextStyle(
                        color: Color(0xFF4E5263),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _ScoreRing(score: item.score, color: item.accent),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(color: Color(0xFFE7EAF3), thickness: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A4FD9),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(34),
                      ),
                    ),
                    child: Text(
                      item.actionLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE5E6EA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.share_outlined,
                    color: Color(0xFF4A4B5D),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score, required this.color});

  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 4,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Text(
            '$score%',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewResultItem {
  final String title;
  final String date;
  final int questionCount;
  final int score;
  final Color accent;
  final IconData icon;
  final Color iconBackground;
  final String actionLabel;
  final String category;

  const _PreviewResultItem({
    required this.title,
    required this.date,
    required this.questionCount,
    required this.score,
    required this.accent,
    required this.icon,
    required this.iconBackground,
    required this.actionLabel,
    required this.category,
  });
}

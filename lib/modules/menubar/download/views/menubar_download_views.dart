import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MenubarDownloadViews extends StatefulWidget {
  const MenubarDownloadViews({super.key});

  @override
  State<MenubarDownloadViews> createState() => _MenubarDownloadViewsState();
}

class _MenubarDownloadViewsState extends State<MenubarDownloadViews> {
  late List<DownloadSectionModel> _sections;

  @override
  void initState() {
    super.initState();
    _sections = _demoSections();
  }

  @override
  Widget build(BuildContext context) {
    final summary = _buildSummary();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      body: SafeArea(
        child: Column(
          children: [
            const _TopBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                children: [
                  _StorageCard(summary: summary),
                  const SizedBox(height: 24),
                  if (_sections.isEmpty)
                    const _EmptyDownloadsView()
                  else ...[
                    ..._sections.map(
                      (section) => Padding(
                        padding: const EdgeInsets.only(bottom: 26),
                        child: _DownloadSection(
                          section: section,
                          onDelete: (item) => _removeItem(section, item),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _clearAllDownloads,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: const BorderSide(
                          color: Color(0xFFC91E1E),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        foregroundColor: const Color(0xFFC91E1E),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 22),
                      label: const Text(
                        'Clear All Downloads',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  StorageSummary _buildSummary() {
    double videoGb = 0;
    double pdfGb = 0;

    for (final section in _sections) {
      for (final item in section.items) {
        final sizeGb = _sizeToGb(item.sizeMb);
        if (item.type == DownloadType.video) {
          videoGb += sizeGb;
        } else {
          pdfGb += sizeGb;
        }
      }
    }

    const totalStorageGb = 64.0;
    final usedGb = videoGb + pdfGb;

    return StorageSummary(
      totalStorageGb: totalStorageGb,
      usedStorageGb: usedGb,
      videoGb: videoGb,
      pdfGb: pdfGb,
    );
  }

  double _sizeToGb(int sizeMb) {
    return sizeMb / 1024;
  }

  void _removeItem(DownloadSectionModel section, DownloadItemModel item) {
    setState(() {
      final targetSection = _sections.firstWhere(
        (entry) => entry.id == section.id,
      );
      targetSection.items.removeWhere((entry) => entry.id == item.id);
      _sections.removeWhere((entry) => entry.items.isEmpty);
    });

    Get.snackbar(
      'Download Removed',
      '${item.title} has been deleted from downloads.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
      colorText: const Color(0xFF1A1D27),
      margin: const EdgeInsets.all(12),
    );
  }

  void _clearAllDownloads() {
    if (_sections.isEmpty) {
      return;
    }

    setState(() {
      _sections = [];
    });

    Get.snackbar(
      'Downloads Cleared',
      'All downloaded files have been removed.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
      colorText: const Color(0xFF1A1D27),
      margin: const EdgeInsets.all(12),
    );
  }

  List<DownloadSectionModel> _demoSections() {
    return [
      DownloadSectionModel(
        id: 'mathematics',
        title: 'Mathematics',
        icon: Icons.functions_rounded,
        color: const Color(0xFF4B49E3),
        items: [
          DownloadItemModel(
            id: 'geometry_video',
            title: 'Intro to Geometry: Angles',
            subtitle: 'Video • 450 MB',
            badge: 'GRADE 8',
            type: DownloadType.video,
            sizeMb: 450,
            accentColor: const Color(0xFF4B49E3),
            previewType: DownloadPreviewType.video,
            previewColors: const [Color(0xFF041119), Color(0xFF172730)],
            previewIcon: Icons.play_circle_outline_rounded,
          ),
          DownloadItemModel(
            id: 'quadratic_pdf',
            title: 'Quadratic Formulas Sheet',
            subtitle: 'PDF • 12 MB',
            badge: 'RESOURCES',
            type: DownloadType.pdf,
            sizeMb: 12,
            accentColor: const Color(0xFF8A2CD5),
            previewType: DownloadPreviewType.pdf,
            previewColors: const [Color(0xFFE7D2FF), Color(0xFFE7D2FF)],
            previewIcon: Icons.picture_as_pdf_outlined,
          ),
        ],
      ),
      DownloadSectionModel(
        id: 'science',
        title: 'Science',
        icon: Icons.science_outlined,
        color: const Color(0xFF8A2CD5),
        items: [
          DownloadItemModel(
            id: 'helix_video',
            title: 'The Double Helix\nStructure',
            subtitle: 'Video • 820 MB',
            badge: 'BIOLOGY',
            type: DownloadType.video,
            sizeMb: 820,
            accentColor: const Color(0xFF8A2CD5),
            previewType: DownloadPreviewType.video,
            previewColors: const [Color(0xFF111320), Color(0xFF3C2A62)],
            previewIcon: Icons.play_circle_outline_rounded,
          ),
        ],
      ),
    ];
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE7EAF3))),
      ),
      child: const Row(
        children: [
          _BackButton(),
          Expanded(
            child: Text(
              'Downloads',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF10388F),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(width: 36),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: Get.back,
      borderRadius: BorderRadius.circular(24),
      child: const SizedBox(
        width: 36,
        height: 36,
        child: Icon(
          Icons.arrow_back_ios_sharp,
          color: Color(0xFF10388F),
          size: 22,
        ),
      ),
    );
  }
}

class _StorageCard extends StatelessWidget {
  const _StorageCard({required this.summary});

  final StorageSummary summary;

  @override
  Widget build(BuildContext context) {
    final usedFraction = summary.usedStorageGb / summary.totalStorageGb;
    final videoFraction = summary.videoGb / summary.totalStorageGb;
    final pdfFraction = summary.pdfGb / summary.totalStorageGb;
    final remainingFraction = (1 - usedFraction).clamp(0.0, 1.0);
    final percent = (usedFraction * 100).round();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5F6B91).withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Device Storage',
            style: TextStyle(
              color: Color(0xFF1C212B),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${summary.usedStorageGb.toStringAsFixed(1)} GB used of ${summary.totalStorageGb.toStringAsFixed(0)} GB available',
                  style: const TextStyle(
                    color: Color(0xFF54586B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCD9FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$percent% Full',
                  style: const TextStyle(
                    color: Color(0xFF4B49E3),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  if (videoFraction > 0)
                    Expanded(
                      flex: (videoFraction * 1000).round(),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF4E57E8), Color(0xFF4B49E3)],
                          ),
                        ),
                      ),
                    ),
                  if (pdfFraction > 0)
                    Expanded(
                      flex: (pdfFraction * 1000).round(),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF8D35D8), Color(0xFF7D1FD0)],
                          ),
                        ),
                      ),
                    ),
                  if (remainingFraction > 0)
                    Expanded(
                      flex: (remainingFraction * 1000).round(),
                      child: Container(color: const Color(0xFFD8DCE3)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 28,
            runSpacing: 12,
            children: [
              _StorageLegend(
                color: const Color(0xFF4B49E3),
                label: 'Videos (${summary.videoGb.toStringAsFixed(1)} GB)',
              ),
              _StorageLegend(
                color: const Color(0xFF7D1FD0),
                label: 'PDFs (${summary.pdfGb.toStringAsFixed(1)} GB)',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StorageLegend extends StatelessWidget {
  const _StorageLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF4F5265),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DownloadSection extends StatelessWidget {
  const _DownloadSection({required this.section, required this.onDelete});

  final DownloadSectionModel section;
  final ValueChanged<DownloadItemModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(section.icon, color: section.color, size: 22),
            const SizedBox(width: 8),
            Text(
              section.title,
              style: const TextStyle(
                color: Color(0xFF1D212B),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...section.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _DownloadCard(item: item, onDelete: () => onDelete(item)),
          ),
        ),
      ],
    );
  }
}

class _DownloadCard extends StatelessWidget {
  const _DownloadCard({required this.item, required this.onDelete});

  final DownloadItemModel item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF616A88).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _DownloadPreview(item: item),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Color(0xFF1D212B),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    color: Color(0xFF55596C),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F1F5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    item.badge,
                    style: const TextStyle(
                      color: Color(0xFF55596C),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(18),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFF56596C),
                size: 25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadPreview extends StatelessWidget {
  const _DownloadPreview({required this.item});

  final DownloadItemModel item;

  @override
  Widget build(BuildContext context) {
    final isPdf = item.previewType == DownloadPreviewType.pdf;

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: item.previewColors,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!isPdf)
            CustomPaint(
              size: const Size(118, 118),
              painter: _PreviewPatternPainter(
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
          Icon(
            isPdf
                ? Icons.picture_as_pdf_outlined
                : Icons.play_circle_outline_rounded,
            color: isPdf ? item.accentColor : Colors.white,
            size: isPdf ? 48 : 56,
          ),
          if (isPdf)
            Positioned(
              bottom: 18,
              child: Container(
                width: 56,
                height: 4,
                decoration: BoxDecoration(
                  color: item.accentColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PreviewPatternPainter extends CustomPainter {
  const _PreviewPatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    canvas.drawCircle(Offset(size.width * 0.34, size.height * 0.34), 18, paint);
    canvas.drawLine(
      Offset(size.width * 0.16, size.height * 0.68),
      Offset(size.width * 0.78, size.height * 0.26),
      paint,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width * 0.68, size.height * 0.66),
        width: 34,
        height: 20,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _PreviewPatternPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _EmptyDownloadsView extends StatelessWidget {
  const _EmptyDownloadsView();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Column(
        children: [
          Icon(Icons.download_done_rounded, color: Color(0xFF4B49E3), size: 45),
          SizedBox(height: 16),
          Text(
            'No Downloads Left',
            style: TextStyle(
              color: Color(0xFF1D212B),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Downloaded files will appear here. Everything has been cleared now.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF666B7E),
              fontSize: 12,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class DownloadSectionModel {
  DownloadSectionModel({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final List<DownloadItemModel> items;
}

class DownloadItemModel {
  const DownloadItemModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.type,
    required this.sizeMb,
    required this.accentColor,
    required this.previewType,
    required this.previewColors,
    required this.previewIcon,
  });

  final String id;
  final String title;
  final String subtitle;
  final String badge;
  final DownloadType type;
  final int sizeMb;
  final Color accentColor;
  final DownloadPreviewType previewType;
  final List<Color> previewColors;
  final IconData previewIcon;
}

class StorageSummary {
  const StorageSummary({
    required this.totalStorageGb,
    required this.usedStorageGb,
    required this.videoGb,
    required this.pdfGb,
  });

  final double totalStorageGb;
  final double usedStorageGb;
  final double videoGb;
  final double pdfGb;
}

enum DownloadType { video, pdf }

enum DownloadPreviewType { video, pdf }

import 'package:flutter/material.dart';

import '../models/question_explanation.dart';

class QuestionExplanationSection extends StatelessWidget {
  const QuestionExplanationSection({
    super.key,
    required this.explanation,
    required this.isLoading,
    required this.errorMessage,
    required this.styles,
    required this.canRegenerate,
    required this.isRegenerating,
    required this.onView,
    required this.onAnother,
    required this.onRegenerate,
    required this.onClose,
  });

  final QuestionExplanationData? explanation;
  final bool isLoading;
  final String errorMessage;
  final List<ExplanationStyle> styles;
  final bool canRegenerate;
  final bool isRegenerating;
  final VoidCallback onView;
  final VoidCallback onAnother;
  final ValueChanged<String> onRegenerate;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    if (explanation == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isLoading) const _LoadingCard(),
          if (errorMessage.isNotEmpty) _ErrorCard(message: errorMessage),
          if (isLoading || errorMessage.isNotEmpty) const SizedBox(height: 10),
          SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onView,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                disabledBackgroundColor: const Color(0xFFFFA184),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.lightbulb_outline_rounded),
              label: Text(
                isLoading ? 'Preparing explanation...' : 'View Explanation',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      );
    }

    final quota = explanation!.quota;
    final hasQuota = (quota?.remaining ?? 0) > 0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD9DFEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 6, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Why is this the answer?',
                    style: TextStyle(
                      color: Color(0xFF202436),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${explanation!.position} of ${explanation!.total}',
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  tooltip: 'Close explanation',
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              explanation!.explanation,
              style: const TextStyle(
                color: Color(0xFF4A5160),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(
              'By ${explanation!.author.isEmpty ? 'a student' : explanation!.author} · ${explanation!.styleLabel}',
              style: const TextStyle(
                color: Color(0xFF667085),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (explanation!.canSeeAnother)
                  OutlinedButton(
                    onPressed: isLoading ? null : onAnother,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('See another explanation'),
                  ),
                if (explanation!.canSeeAnother && canRegenerate)
                  const SizedBox(height: 8),
                if (canRegenerate)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              isLoading ||
                                  (quota != null && !hasQuota) ||
                                  styles.isEmpty
                              ? null
                              : () => _openStylePicker(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5722),
                            disabledBackgroundColor: const Color(0xFFE1E5EC),
                            foregroundColor: Colors.white,
                            disabledForegroundColor: const Color(0xFF98A2B3),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isRegenerating
                              ? const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text('Generating...'),
                                  ],
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.refresh_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Regenerate'),
                                  ],
                                ),
                        ),
                      ),
                      if (quota != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          '${quota.remaining} of ${quota.limit} left today',
                          style: const TextStyle(
                            color: Color(0xFF667085),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openStylePicker(BuildContext context) async {
    String selectedStyle = styles.first.key;
    final style = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How should we explain it?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                ...styles.map(
                  (style) => RadioListTile<String>(
                    value: style.key,
                    groupValue: selectedStyle,
                    contentPadding: EdgeInsets.zero,
                    title: Text(style.label),
                    subtitle: Text(style.hint),
                    onChanged: (value) =>
                        setState(() => selectedStyle = value!),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, selectedStyle),
                      child: const Text('Create'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (style != null) onRegenerate(style);
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: 10),
        Text('Preparing explanation...'),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(message, style: const TextStyle(color: Color(0xFFB42318))),
    );
  }
}

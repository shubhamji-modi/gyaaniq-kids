import 'package:flutter/material.dart';

/// A subject's themed icon + brand colour, resolved from its name so the same
/// subject looks identical everywhere (Learn, E-Books, Practice Quiz).
class SubjectVisual {
  const SubjectVisual({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  /// Soft tint for card backgrounds.
  Color get softBackground => Color.alphaBlend(
    color.withValues(alpha: 0.10),
    Colors.white,
  );
}

/// Maps a subject name (English/Hindi keywords supported) to its icon + colour.
/// Falls back to a neutral indigo book for anything not recognised.
SubjectVisual subjectVisualFor(String name) {
  final key = name.trim().toLowerCase();
  bool has(String s) => key.contains(s);

  // Order matters: match specific subjects before the generic "science".
  if (has('social') ||
      has('sst') ||
      has('history') ||
      has('civic') ||
      has('geograph')) {
    return const SubjectVisual(
      icon: Icons.public_rounded,
      color: Color(0xFF2E90E8), // blue
    );
  }
  if (has('math') || has('गणित')) {
    return const SubjectVisual(
      icon: Icons.calculate_rounded,
      color: Color(0xFF2FA84F), // green
    );
  }
  if (has('hindi') || has('हिंदी') || has('हिन्दी')) {
    return const SubjectVisual(
      icon: Icons.translate_rounded,
      color: Color(0xFF12A594), // teal
    );
  }
  if (has('english') || has('अंग्रेज')) {
    return const SubjectVisual(
      icon: Icons.menu_book_rounded,
      color: Color(0xFFF2A20C), // amber
    );
  }
  if (has('chem')) {
    return const SubjectVisual(
      icon: Icons.science_rounded,
      color: Color(0xFF7A48E0), // purple
    );
  }
  if (has('physic')) {
    return const SubjectVisual(
      icon: Icons.bolt_rounded,
      color: Color(0xFF6D3BD1), // deep purple
    );
  }
  if (has('bio')) {
    return const SubjectVisual(
      icon: Icons.eco_rounded,
      color: Color(0xFF2FA84F), // green
    );
  }
  if (has('science') || has('विज्ञान')) {
    return const SubjectVisual(
      icon: Icons.science_rounded,
      color: Color(0xFF7A48E0), // purple
    );
  }
  if (has('computer') || has('coding') || has('comp')) {
    return const SubjectVisual(
      icon: Icons.computer_rounded,
      color: Color(0xFF2E90E8), // blue
    );
  }
  if (has('sanskrit') || has('संस्कृत')) {
    return const SubjectVisual(
      icon: Icons.auto_stories_rounded,
      color: Color(0xFFB8860B), // dark amber
    );
  }
  if (has('evs') || has('environ')) {
    return const SubjectVisual(
      icon: Icons.eco_rounded,
      color: Color(0xFF12A594), // teal
    );
  }
  if (has('gk') || has('general knowledge')) {
    return const SubjectVisual(
      icon: Icons.lightbulb_rounded,
      color: Color(0xFFD6336C), // pink
    );
  }
  return const SubjectVisual(
    icon: Icons.menu_book_rounded,
    color: Color(0xFF4A4FD9), // indigo
  );
}

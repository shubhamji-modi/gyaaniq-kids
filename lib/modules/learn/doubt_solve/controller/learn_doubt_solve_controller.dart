import 'package:flutter/material.dart';

class LearnDoubtSolveRepository {
  static const List<String> filters = [
    'All Subject',
    'Math',
    'Science',
    'History',
  ];

  static const List<LearnExpertModel> experts = [
    LearnExpertModel(
      name: 'Sarah Mitchell',
      title: 'Senior Math Expert',
      subject: 'Math',
      rating: '4.9',
      accent: Color(0xFF4A4FD9),
      imageBackground: Color(0xFF7D5E44),
      description:
          'Helping students master complex math concepts since 2015. Expert in making abstract algebra easy to understand.',
      tags: ['Algebra', 'Calculus', 'SAT Prep'],
    ),
    LearnExpertModel(
      name: 'David Chen',
      title: 'Physics Specialist',
      subject: 'Science',
      rating: '4.8',
      accent: Color(0xFF7D31E2),
      imageBackground: Color(0xFF2F5668),
      description:
          'Specializing in high school physics and competitive exam preparation with practical problem-solving techniques.',
      tags: ['Quantum Mechanics', 'Optics'],
    ),
    LearnExpertModel(
      name: 'Elena Rodriguez',
      title: 'Biology Mentor',
      subject: 'Science',
      rating: '5.0',
      accent: Color(0xFFA46A00),
      imageBackground: Color(0xFF61324A),
      description:
          'Passionate about life sciences and helping students visualize complex biological systems with simple analogies.',
      tags: ['Genetics', 'Ecology'],
    ),
    LearnExpertModel(
      name: 'James Wilson',
      title: 'History Expert',
      subject: 'History',
      rating: '4.7',
      accent: Color(0xFF7D31E2),
      imageBackground: Color(0xFF5E4934),
      description:
          'Making history come alive through storytelling and critical analysis for essays, source work, and revision.',
      tags: ['World Wars', 'Civics'],
    ),
  ];
}

class LearnExpertModel {
  final String name;
  final String title;
  final String subject;
  final String rating;
  final Color accent;
  final Color imageBackground;
  final String description;
  final List<String> tags;

  const LearnExpertModel({
    required this.name,
    required this.title,
    required this.subject,
    required this.rating,
    required this.accent,
    required this.imageBackground,
    required this.description,
    required this.tags,
  });
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../../core/data/user_profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/service/api_service.dart';
import '../../core/values/constants.dart';
import '../../routes/app_routes.dart';

class StudentProfileSetupViews extends StatefulWidget {
  const StudentProfileSetupViews({super.key});

  @override
  State<StudentProfileSetupViews> createState() =>
      _StudentProfileSetupViewsState();
}

class _StudentProfileSetupViewsState extends State<StudentProfileSetupViews> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _boardSearchController = TextEditingController();
  final TextEditingController _boardSheetSearchController =
      TextEditingController();
  final FocusNode _boardSheetSearchFocusNode = FocusNode();

  final List<String> _languages = const [
    'English',
    'Hindi',
    'Marathi',
    'Tamil',
    'Telugu',
    'Gujarati',
    'Malayalam',
    'Bengali',
    'Other',
    'Odia',
    'Kashmiri',
    'Nepali',
    'Manipuri',
    'Bodo',
    'Konkani',
  ];

  final List<String> _classes = const [
    '5th',
    '6th',
    '7th',
    '8th',
    '9th',
    '10th',
  ];

  final List<String> _primaryBoards = const [
    'CBSE',
    'ICSE',
    'IGCSE',
    'State Board',
    'Maharashtra Board',
  ];

  final List<String> _allBoards = const [
    'Andhra Pradesh Board of Intermediate Education - BIEAP',
    'Andhra Pradesh Board of Secondary Education - BSEAP',
    'Andhra Pradesh Open School Society, SCERT Campus - APOSS',
    'Assam Higher Secondary Education Council - AHSEC',
    'Board of Secondary Education Assam - SEBA',
    'Bihar Intermediate Education Council - BIEC',
    'Bihar School Examination Board - BSEB',
    'Bihar Sanskrit Shiksha Board - BSSB Patna',
    'Bihar Board of Open Schooling & Examination - BBOSE',
    'CBSE',
    'ICSE',
    'IGCSE',
    'Maharashtra Board',
    'State Board',
  ];

  int _currentStep = 0;
  String? _selectedLanguage;
  String? _selectedBoard;
  String? _selectedFinalGrade;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _boardSearchController.dispose();
    _boardSheetSearchController.dispose();
    _boardSheetSearchFocusNode.dispose();
    super.dispose();
  }

  bool get _canContinue {
    switch (_currentStep) {
      case 0:
        return _nameController.text.trim().isNotEmpty;
      case 1:
        return _selectedLanguage != null;
      // case 2:
      //   return _selectedClass != null;
      case 2:
        return _selectedBoard != null;
      case 3:
        return _selectedFinalGrade != null;
      default:
        return false;
    }
  }

  Future<void> _onContinue() async {
    if (!_canContinue) {
      return;
    }

    if (_currentStep == 3) {
      final profileProvider = context.read<UserProfileProvider>();

      setState(() {
        _isSubmitting = true;
      });

      final response = await ApiService.instance.put<dynamic>(
        endpoint: ApiService.STUDENT_PROFILE_SETUP,
        data: {
          'name': _nameController.text.trim(),
          'instructionMedium': _selectedLanguage,
          'classLevel': _selectedFinalGrade,
          'educationalBoard': _selectedBoard,
        },
        fromJson: (json) => json,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      if (!response.success || response.data is! Map<String, dynamic>) {
        _showMessage(response.message, isError: true);
        return;
      }

      final body = response.data as Map<String, dynamic>;
      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        _showMessage(
          body['message']?.toString() ?? 'Profile setup failed',
          isError: true,
        );
        return;
      }

      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(StorageKeys.profileSetupCompleted, true);

      profileProvider.setProfile(UserProfile.fromApi(data));

      _showMessage(body['message']?.toString() ?? 'Profile setup successful');
      Get.offAllNamed(AppRoutes.dashboard);
      return;
    }

    if (mounted) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _onBack() {
    if (_currentStep == 0) {
      Get.back();
      return;
    }

    setState(() {
      _currentStep--;
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    Get.snackbar(
      isError ? 'Error' : 'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError
          ? const Color(0xFFB42318)
          : const Color(0xFF0F9D58),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  void _openBoardSheet() {
    _boardSheetSearchController.text = _boardSearchController.text;
    String query = _boardSheetSearchController.text;
    String? tempSelection = _selectedBoard;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredBoards = _allBoards
                .where(
                  (board) =>
                      board.toLowerCase().contains(query.trim().toLowerCase()),
                )
                .toList();

            return SafeArea(
              child: Container(
                height: MediaQuery.of(context).size.height * 0.84,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6DCEA),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Select your Board',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SearchField(
                      controller: _boardSheetSearchController,
                      focusNode: _boardSheetSearchFocusNode,
                      hintText: 'Find other Board',
                      onChanged: (value) {
                        setModalState(() {
                          query = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: filteredBoards.length,
                        separatorBuilder: (_, index) =>
                            const Divider(height: 1, color: Color(0xFFE9EDF5)),
                        itemBuilder: (context, index) {
                          final board = filteredBoards[index];
                          final isSelected = tempSelection == board;

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              board,
                              style: const TextStyle(
                                color: Color(0xFF121926),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                            trailing: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF4A4FD9)
                                      : const Color(0xFFC2C8D8),
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Center(
                                      child: CircleAvatar(
                                        radius: 6,
                                        backgroundColor: Color(0xFF4A4FD9),
                                      ),
                                    )
                                  : null,
                            ),
                            onTap: () {
                              setModalState(() {
                                tempSelection = board;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: tempSelection == null
                            ? null
                            : () {
                                setState(() {
                                  _selectedBoard = tempSelection;
                                  _boardSearchController.text = tempSelection!;
                                });
                                Navigator.of(context).pop();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A4FD9),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFF1F3F8),
                          disabledForegroundColor: const Color(0xFFB1B8C8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _boardSheetSearchFocusNode.unfocus();
      _boardSheetSearchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentStep + 1) / 4;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Row(
                children: [
                  if (_currentStep != 0) ...[
                    InkWell(
                      onTap: _onBack,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFF1B2436),
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE6E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF4A4FD9),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    _currentStep == 3
                        ? 'final Step'
                        : 'Step ${_currentStep + 1} of 4',
                    style: const TextStyle(
                      color: Color(0xFF6D7385),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 34, 20, 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _buildStepContent(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 22),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_canContinue && !_isSubmitting)
                      ? _onContinue
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A4FD9),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFD9DDF3),
                    disabledForegroundColor: const Color(0xFF8D96B8),
                    elevation: 12,
                    shadowColor: const Color(
                      0xFF4A4FD9,
                    ).withValues(alpha: 0.28),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isSubmitting
                            ? 'Please wait...'
                            : _currentStep == 3
                            ? 'Start Learning'
                            : 'Continue',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 22),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildNameStep();
      case 1:
        return _buildLanguageStep();
      // case 2:
      //   return _buildClassStep();
      case 2:
        return _buildBoardStep();
      case 3:
        return _buildFinalGradeStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNameStep() {
    return Column(
      key: const ValueKey('name-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
        const Text(
          'Enter Your Name?',
          style: TextStyle(
            color: Color(0xFF17263B),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _nameController,
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: 'Enter your full name',
            hintStyle: const TextStyle(
              color: Color(0xFF8A91A5),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            suffixIcon: const Icon(
              Icons.person_outline_rounded,
              color: Color(0xFFC0C5D2),
            ),
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFC9CEDD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFC9CEDD)),
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
      ],
    );
  }

  Widget _buildLanguageStep() {
    return Column(
      key: const ValueKey('language-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 1),
        const Text(
          'Instruction Medium',
          style: TextStyle(
            color: Color(0xFF17263B),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 16,
          children: _languages.map((language) {
            final isSelected = _selectedLanguage == language;
            return _SelectionChip(
              label: language,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _selectedLanguage = language;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBoardStep() {
    return Column(
      key: const ValueKey('board-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 1),
        const Text(
          'Educational Board',
          style: TextStyle(
            color: Color(0xFF17263B),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 15),
        GestureDetector(
          onTap: _openBoardSheet,
          child: AbsorbPointer(
            child: _SearchField(
              controller: _boardSearchController,
              hintText: 'Find other state board',
            ),
          ),
        ),
        const SizedBox(height: 26),
        Wrap(
          spacing: 10,
          runSpacing: 12,
          children: _primaryBoards.map((board) {
            final isSelected = _selectedBoard == board;
            return _RectangularOption(
              label: board,
              isSelected: isSelected,
              width: board == 'Maharashtra Board' ? 204 : 110,
              onTap: () {
                setState(() {
                  _selectedBoard = board;
                  _boardSearchController.text = board;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFinalGradeStep() {
    const icons = <String, IconData>{
      '5th': Icons.menu_book_outlined,
      '6th': Icons.science_outlined,
      '7th': Icons.calculate_outlined,
      '8th': Icons.edit_note_rounded,
      '9th': Icons.language_rounded,
      '10th': Icons.psychology_alt_outlined,
    };

    return Column(
      key: const ValueKey('final-grade-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 1),
        const Text(
          'Which class are you in?',
          textAlign: TextAlign.left,
          style: TextStyle(
            color: Color(0xFF17263B),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Select your current grade to customize your learning journey.',
          textAlign: TextAlign.left,
          style: TextStyle(
            color: Color(0xFF565C6D),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 34),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _classes.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.70,
          ),
          itemBuilder: (context, index) {
            final className = _classes[index];
            final isSelected = _selectedFinalGrade == className;

            return _GradeCard(
              label: className,
              icon: icons[className] ?? Icons.school_outlined,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _selectedFinalGrade = className;
                });
              },
            );
          },
        ),
      ],
    );
  }
}

class _SelectionChip extends StatelessWidget {
  const _SelectionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE4E7FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF133E95)
                : const Color(0xFFC4C9D9),
            width: isSelected ? 1.8 : 1.4,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFF133E95)
                : const Color(0xFF41485A),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _RectangularOption extends StatelessWidget {
  const _RectangularOption({
    required this.label,
    required this.isSelected,
    required this.width,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A4FD9) : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4A4FD9)
                : const Color(0xFFC4C9D9),
            width: 1.4,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4A4FD9).withValues(alpha: 0.24),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF41485A),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.focusNode,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      inputFormatters: const [],
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF8A91A5),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFC0C5D2)),
        suffixIcon: onChanged == null
            ? const Icon(null, color: Color(0xFFC0C5D2))
            : null,
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFC9CEDD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFC9CEDD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4A4FD9), width: 1.5),
        ),
      ),
    );
  }
}

class _GradeCard extends StatelessWidget {
  const _GradeCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A4FD9) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4A4FD9)
                : const Color(0xFFD8DDF0),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  (isSelected
                          ? const Color(0xFF4A4FD9)
                          : const Color(0xFFBCC4E3))
                      .withValues(alpha: 0.24),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (isSelected)
              const Positioned(
                top: 5,
                right: 5,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.green,
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? const Color(0xFF6065ED)
                          : const Color(0xFFF2F4FA),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF4A4FD9),
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF1F2430),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Grade',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.88)
                          : const Color(0xFF666E82),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
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

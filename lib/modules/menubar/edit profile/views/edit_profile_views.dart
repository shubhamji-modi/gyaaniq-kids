import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../../core/data/user_profile_provider.dart';

class EditProfileViews extends StatefulWidget {
  const EditProfileViews({super.key});

  @override
  State<EditProfileViews> createState() => _EditProfileViewsState();
}

class _EditProfileViewsState extends State<EditProfileViews> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  String _selectedGrade = 'Grade 8';

  final List<String> _grades = const [
    'Grade 5',
    'Grade 6',
    'Grade 7',
    'Grade 8',
    'Grade 9',
    'Grade 10',
  ];

  @override
  void initState() {
    super.initState();
    final profile = context.read<UserProfileProvider>().profile;
    final profileName = profile?.name ?? 'Alex Johnson';
    final classNumber = profile?.userClass ?? '8';

    _nameController = TextEditingController(text: profileName);
    _phoneController = TextEditingController(text: '+91 1234567890');
    _selectedGrade = 'Grade $classNumber';
    if (!_grades.contains(_selectedGrade)) {
      _selectedGrade = 'Grade 8';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final provider = context.read<UserProfileProvider>();
    final currentProfile = provider.profile;
    final updatedName = _nameController.text.trim().isEmpty
        ? 'Student'
        : _nameController.text.trim();
    final updatedClass = _selectedGrade.replaceFirst('Grade ', '');

    provider.setProfile(
      UserProfile(
        name: updatedName,
        instructionMedium: currentProfile?.instructionMedium ?? 'English',
        educationBoard: currentProfile?.educationBoard ?? 'CBSE',
        userClass: updatedClass,
      ),
    );

    Get.snackbar(
      'Profile Updated',
      'Your profile changes have been saved successfully.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.white,
      colorText: const Color(0xFF1D2231),
      margin: const EdgeInsets.all(14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<UserProfileProvider>().profile;
    final displayName = _nameController.text.trim().isEmpty
        ? (profile?.name ?? 'Alex Johnson')
        : _nameController.text.trim();
    final email = '${displayName.toLowerCase().replaceAll(' ', '.')}@gmail.com';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      body: SafeArea(
        child: Column(
          children: [
            const _EditProfileTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                child: Column(
                  children: [
                    _ProfileHeader(name: displayName),
                    const SizedBox(height: 28),
                    _SectionCard(
                      title: 'Personal Details',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel(title: 'Full Name'),
                          _InputField(controller: _nameController),
                          const SizedBox(height: 22),
                          const _FieldLabel(title: 'Email Address (Primary)'),
                          _ReadOnlyField(
                            value: email,
                            trailing: const Icon(
                              Icons.lock_rounded,
                              color: Color(0xFF7B7C91),
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 22),
                          const _FieldLabel(title: 'Phone Number'),
                          _InputField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SectionCard(
                      title: 'Academic Path',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel(title: 'Current Grade'),
                          _GradeDropdown(
                            value: _selectedGrade,
                            items: _grades,
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() {
                                _selectedGrade = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF7B7C91),
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Premium Member since 2023',
                          style: TextStyle(
                            color: Color(0xFF7B7C91),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: const Color(0xFF4B49E3),
                          foregroundColor: Colors.white,
                          shadowColor: const Color(0xFF4B49E3).withValues(
                            alpha: 0.35,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(42),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(Icons.check_circle_outline_rounded, size: 20),
                          ],
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

class _EditProfileTopBar extends StatelessWidget {
  const _EditProfileTopBar();

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
              color: Color(0xFF4B49E3),
              size: 22,
            ),
          ),
          const Expanded(
            child: Text(
              'Edit Profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF4B49E3),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 130,
              height: 130,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF4F6FF),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFCDD5EA).withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFF7A30),
                    width: 2,
                  ),
                ),
                child: const CircleAvatar(
                  backgroundColor: Color(0xFFFFD0AF),
                  child: Icon(
                    Icons.person_rounded,
                    size: 45,
                    color: Color(0xFF7D4B2C),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 4,
              child: Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4B49E3),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          name.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF45475B),
            fontSize: 16,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD2D8E7).withValues(alpha: 0.26),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
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
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF787A8F),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    this.keyboardType,
  });

  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Color(0xFF1D2231),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF3F4F8),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0xFF4B49E3), width: 1.5),
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.value,
    this.trailing,
  });

  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F8),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF7B7C91),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          trailing ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _GradeDropdown extends StatelessWidget {
  const _GradeDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F8),
        borderRadius: BorderRadius.circular(22),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF7B7C91),
            size: 25,
          ),
          style: const TextStyle(
            color: Color(0xFF1D2231),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          items: items
              .map(
                (grade) => DropdownMenuItem<String>(
                  value: grade,
                  child: Text(grade),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

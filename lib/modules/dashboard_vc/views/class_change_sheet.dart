import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../../core/data/class_catalogue.dart';
import '../../../core/data/user_profile_provider.dart';
import '../../../core/service/api_service.dart';

/// Bottom sheet that lets a student change their class from the dashboard.
///
/// Fetches [ClassCatalogueRepository.fetchActiveClasses] on open, shows the
/// current class pre-selected, and submits via the same
/// `PUT user/profile/setup` endpoint used by full profile edits — sending the
/// existing profile fields alongside the new `classLevel` so other fields are
/// left untouched. The backend enforces the `classChangeByUser` policy
/// (e.g. rejecting an already-set class change with 403), so failures are
/// surfaced as-is rather than re-validated on the client.
Future<void> showClassChangeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => const _ClassChangeSheet(),
  );
}

class _ClassChangeSheet extends StatefulWidget {
  const _ClassChangeSheet();

  @override
  State<_ClassChangeSheet> createState() => _ClassChangeSheetState();
}

class _ClassChangeSheetState extends State<_ClassChangeSheet> {
  bool _loading = true;
  bool _submitting = false;
  String _error = '';
  List<ClassOption> _classes = const [];
  String? _selectedClass;

  @override
  void initState() {
    super.initState();
    _selectedClass = context.read<UserProfileProvider>().profile?.userClass;
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    final response = await ClassCatalogueRepository.fetchActiveClasses();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (response.success) {
        _classes = response.data ?? const [];
      } else {
        _error = response.message;
      }
    });
  }

  Future<void> _submit() async {
    final provider = context.read<UserProfileProvider>();
    final currentProfile = provider.profile;
    final selected = _selectedClass;
    if (currentProfile == null || selected == null || _submitting) {
      return;
    }

    setState(() => _submitting = true);

    final response = await ApiService.instance.put<dynamic>(
      endpoint: ApiService.EDIT_PROFILE,
      data: {...currentProfile.toProfilePayload(), 'classLevel': selected},
      fromJson: (json) => json,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    final body = response.data;
    final message = body is Map<String, dynamic>
        ? body['message']?.toString() ?? response.message
        : response.message;

    if (!response.success) {
      Get.snackbar(
        'Error',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFB42318),
        colorText: Colors.white,
        margin: const EdgeInsets.all(14),
      );
      return;
    }

    provider.setProfile(currentProfile.copyWith(userClass: selected));

    if (!mounted) return;
    Navigator.pop(context);
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF1B8A5A),
      colorText: Colors.white,
      margin: const EdgeInsets.all(14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4D7E2),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Change Class',
                        style: TextStyle(
                          color: Color(0xFF1D2231),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Select your current class',
                        style: TextStyle(
                          color: Color(0xFF7B7C91),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Color(0xFF6B6E80),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildBody(),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_selectedClass == null || _submitting)
                    ? null
                    : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4B49E3),
                  disabledBackgroundColor: const Color(0xFFC9C8F0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
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
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4B49E3)),
            ),
          ),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(
                _error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF9A2F2F),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(onPressed: _loadClasses, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_classes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'No classes available right now.',
            style: TextStyle(
              color: Color(0xFF7B7C91),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _classes.map((option) {
        final selected = _selectedClass == option.className;
        return _ClassChip(
          label: option.className,
          selected: selected,
          onTap: () => setState(() => _selectedClass = option.className),
        );
      }).toList(),
    );
  }
}

class _ClassChip extends StatelessWidget {
  const _ClassChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF4B49E3) : const Color(0xFFF3F4F8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xFF4B49E3)
                : const Color(0xFFE4E6F1),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF1D2231),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

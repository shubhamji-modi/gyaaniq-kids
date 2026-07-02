import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/service/api_service.dart';

class LeaderboardController extends GetxController {
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final RxString classLevel = ''.obs;
  final RxInt totalStudents = 0.obs;
  final RxInt myRank = 0.obs;
  final RxBool myInTop = false.obs;
  final RxList<LeaderboardUser> top = <LeaderboardUser>[].obs;
  final Rxn<LeaderboardUser> myEntry = Rxn<LeaderboardUser>();

  // Class prizes (shown in the header bottom sheet).
  final RxBool isLoadingPrizes = false.obs;
  final RxString prizesError = ''.obs;
  final RxString prizesClassLevel = ''.obs;
  final RxList<ClassPrize> classPrizes = <ClassPrize>[].obs;

  List<LeaderboardUser> get topThree => top.take(3).toList();

  LeaderboardUser? get currentUser => myEntry.value;

  List<LeaderboardUser> get rankings => top.skip(3).toList();

  @override
  void onInit() {
    super.onInit();
    loadLeaderboard();
  }

  Future<void> loadLeaderboard() async {
    isLoading.value = true;
    errorMessage.value = '';

    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.USER_LEADERBOARD,
      showLoader: false,
      fromJson: (json) => json,
      queryParameters: const {'topLimit': 10},
    );

    isLoading.value = false;

    if (!response.success || response.data is! Map<String, dynamic>) {
      errorMessage.value = response.message;
      top.clear();
      myEntry.value = null;
      return;
    }

    final body = response.data as Map<String, dynamic>;
    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    classLevel.value = _safeText(data['classLevel']);
    totalStudents.value = (data['totalStudents'] as num?)?.toInt() ?? 0;
    myRank.value = (data['myRank'] as num?)?.toInt() ?? 0;
    myInTop.value = data['myInTop'] == true;
    top.assignAll(
      (data['top'] as List<dynamic>? ?? const []).map(
        (item) => LeaderboardUser.fromApi(item as Map<String, dynamic>),
      ),
    );
    final entryJson = data['myEntry'];
    myEntry.value = entryJson is Map<String, dynamic>
        ? LeaderboardUser.fromApi(
            entryJson,
            subtitle: myRank.value > 0 ? 'Ranked #${myRank.value}' : null,
          )
        : null;
  }

  Future<void> loadClassPrizes() async {
    if (isLoadingPrizes.value) {
      return;
    }
    isLoadingPrizes.value = true;
    prizesError.value = '';

    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.CLASS_PRIZES,
      showLoader: false,
      fromJson: (json) => json,
    );

    isLoadingPrizes.value = false;

    if (!response.success || response.data is! Map<String, dynamic>) {
      classPrizes.clear();
      prizesError.value = response.message.isEmpty
          ? 'Unable to load class prizes right now.'
          : response.message;
      return;
    }

    final body = response.data as Map<String, dynamic>;
    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    prizesClassLevel.value = _safeText(data['classLevel']);
    classPrizes.assignAll(
      (data['prizes'] as List<dynamic>? ?? const [])
          .map((item) => ClassPrize.fromApi(item as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.rank.compareTo(b.rank)),
    );
  }

  String formatXp(int value) {
    final valueText = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < valueText.length; i++) {
      final reverseIndex = valueText.length - i;
      buffer.write(valueText[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }
    return '${buffer.toString()} XP';
  }

}

class LeaderboardUser {

  const LeaderboardUser({
    required this.rank,
    required this.name,
    required this.xp,
    required this.initials,
    required this.avatarGradient,
    required this.ringColor,
    this.subtitle,
    this.isChampion = false,
  });

  final int rank;
  final String name;
  final int xp;
  final String initials;
  final List<Color> avatarGradient;
  final Color ringColor;
  final String? subtitle;
  final bool isChampion;

  factory LeaderboardUser.fromApi(
    Map<String, dynamic> json, {
    String? subtitle,
  }) {
    final student = (json['student'] as Map<String, dynamic>?) ?? const {};
    final rank = (json['rank'] as num?)?.toInt() ?? 0;
    final name = _safeText(student['name'], fallback: 'Student');
    return LeaderboardUser(
      rank: rank,
      name: name,
      xp: (json['score'] as num?)?.toInt() ?? 0,
      initials: _initials(name),
      avatarGradient: _avatarGradient(rank),
      ringColor: rank == 1
          ? const Color(0xFFFFA81E)
          : rank == 2
          ? const Color(0xFFD6D0EF)
          : const Color(0xFFFFB46A),
      subtitle: subtitle,
      isChampion: rank == 1,
    );
  }

}

class ClassPrize {
  const ClassPrize({
    required this.rank,
    required this.name,
    this.imageUrl,
  });

  final int rank;
  final String name;
  final String? imageUrl;

  factory ClassPrize.fromApi(Map<String, dynamic> json) {
    final image = json['image'];
    final url = image is Map<String, dynamic> ? _safeText(image['url']) : '';
    return ClassPrize(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      name: _safeText(json['name'], fallback: 'Prize'),
      imageUrl: url.isEmpty ? null : url,
    );
  }

  
}

String _safeText(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _initials(String name) {
  final parts = name
      .split(RegExp(r'\s+'))
      .where((part) => part.trim().isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return 'ST';
  }
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}

List<Color> _avatarGradient(int rank) {
  switch (rank) {
    case 1:
      return const [Color(0xFFFFD561), Color(0xFF9F4B11)];
    case 2:
      return const [Color(0xFF71D7D4), Color(0xFF3A6EA8)];
    case 3:
      return const [Color(0xFF2A6BC6), Color(0xFF101C33)];
    default:
      return const [Color(0xFF7ED0FF), Color(0xFF1F4B72)];
  }
}

import 'package:get/get.dart';

import '../models/question_explanation.dart';
import 'api_service.dart';

class ExplanationCatalogService extends GetxService {
  static ExplanationCatalogService get instance =>
      Get.find<ExplanationCatalogService>();

  final RxList<ExplanationStyle> styles = <ExplanationStyle>[].obs;
  final RxBool isLoading = false.obs;

  Future<bool> loadStyles() async {
    if (styles.isNotEmpty) return true;
    if (isLoading.value) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return styles.isNotEmpty;
    }

    isLoading.value = true;
    final response = await ApiService.instance.get<dynamic>(
      endpoint: ApiService.GET_EXPLANATION_STYLES,
      showLoader: false,
      fromJson: (json) => json,
    );
    isLoading.value = false;

    if (!response.success || response.data is! Map<String, dynamic>) {
      return false;
    }
    final data = (response.data as Map<String, dynamic>)['data'];
    if (data is! Map<String, dynamic>) return false;
    styles.assignAll(
      (data['styles'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ExplanationStyle.fromApi)
          .where((style) => style.key.isNotEmpty && style.label.isNotEmpty),
    );
    return styles.isNotEmpty;
  }
}

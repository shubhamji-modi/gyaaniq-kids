import 'package:get/get.dart';

class LearnProgressRefreshService extends GetxService {
  static LearnProgressRefreshService get instance {
    if (Get.isRegistered<LearnProgressRefreshService>()) {
      return Get.find<LearnProgressRefreshService>();
    }
    return Get.put(LearnProgressRefreshService());
  }

  final RxInt refreshTick = 0.obs;

  void notifyRefresh() {
    refreshTick.value++;
  }
}

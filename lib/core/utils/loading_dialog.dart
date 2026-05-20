import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoadingDialog {
  static bool _isShowing = false;

  static void show({String? message}) {
    if (_isShowing) return;

    _isShowing = true;
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Get.theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF4A4FD9),
                    ),
                    strokeWidth: 3,
                  ),
                ),
                if (message != null) ...[
                  SizedBox(height: 16),
                  Text(
                    message,
                    style: Get.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
      name: 'LoadingDialog',
    );
  }

  static void hide() {
    if (!_isShowing) return;

    _isShowing = false;
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }

  static Widget buildInlineLoader({
    String? message,
    double? size,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size ?? 30,
            height: size ?? 30,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFF4A4FD9),
              ),
              strokeWidth: 2,
            ),
          ),
          if (message != null) ...[
            SizedBox(height: 12),
            Text(
              message,
              style: Get.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
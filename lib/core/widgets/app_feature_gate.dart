import 'package:flutter/material.dart';

import '../service/app_features_service.dart';

/// Rebuilds [builder] whenever a fresh answer arrives from
/// `GET user/app-features`.
///
/// For places that do more than show or hide one widget — a menu that filters
/// its own entries, say. Where a whole section is shown or hidden, use
/// [AppFeatureGate] instead.
class AppFeaturesBuilder extends StatelessWidget {
  const AppFeaturesBuilder({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppFeaturesService.instance.revision,
      builder: (context, _, _) => builder(context),
    );
  }
}

/// Shows [child] only while the admin has [feature] switched on for this
/// student's class, and rebuilds itself whenever a fresh answer arrives from
/// `GET user/app-features`.
///
/// Use it around whole sections/entry points; the section's own APIs should sit
/// behind the same check so a hidden section never calls them.
class AppFeatureGate extends StatelessWidget {
  const AppFeatureGate({
    super.key,
    required this.feature,
    required this.child,
    this.placeholder = const SizedBox.shrink(),
  });

  /// A key from [AppFeaturesService], e.g. `AppFeaturesService.classPrizes`.
  final String feature;

  final Widget child;

  /// Shown in place of [child] when the section is switched off. Defaults to
  /// nothing at all, which is what "hide the section" means almost everywhere.
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    final features = AppFeaturesService.instance;
    return ValueListenableBuilder<int>(
      valueListenable: features.revision,
      builder: (context, _, _) {
        return features.isEnabled(feature) ? child : placeholder;
      },
    );
  }
}

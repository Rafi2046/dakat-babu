import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../animated_living_background.dart';

/// Portrait game shell: living background + safe area + optional bars.
class AppShell extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? topBar;
  final Widget? bottomNavigation;
  final bool useLivingBackground;
  final EdgeInsetsGeometry? padding;

  const AppShell({
    super.key,
    required this.body,
    this.topBar,
    this.bottomNavigation,
    this.useLivingBackground = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (topBar != null) topBar!,
          Expanded(
            child: Padding(
              padding: padding ?? AppSpacing.screenPadding,
              child: body,
            ),
          ),
          if (bottomNavigation != null) bottomNavigation!,
        ],
      ),
    );

    return Scaffold(
      body: useLivingBackground
          ? AnimatedLivingBackground(child: content)
          : content,
    );
  }
}

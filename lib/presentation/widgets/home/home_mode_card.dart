import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_strings_bn.dart';
import '../../../core/constants/home_text_styles.dart';

enum HomeModeCardState { enabled, disabled, comingSoon }

/// Full-width or half-width colorful mode entry card.
class HomeModeCard extends StatelessWidget {
  final String title;
  final String? tag;
  final String subtitle;
  final String? meta;
  final IconData icon;
  final Color color;
  final Color deepColor;
  final VoidCallback? onTap;
  final HomeModeCardState state;
  final bool compact;

  const HomeModeCard({
    super.key,
    required this.title,
    this.tag,
    required this.subtitle,
    this.meta,
    required this.icon,
    required this.color,
    required this.deepColor,
    this.onTap,
    this.state = HomeModeCardState.enabled,
    this.compact = false,
  });

  factory HomeModeCard.half({
    Key? key,
    required String title,
    required String subtitle,
    required String meta,
    required IconData icon,
    required Color color,
    required Color deepColor,
    VoidCallback? onTap,
    HomeModeCardState state = HomeModeCardState.enabled,
  }) {
    return HomeModeCard(
      key: key,
      title: title,
      subtitle: subtitle,
      meta: meta,
      icon: icon,
      color: color,
      deepColor: deepColor,
      onTap: onTap,
      state: state,
      compact: true,
    );
  }

  bool get _interactive =>
      state == HomeModeCardState.enabled && onTap != null;

  @override
  Widget build(BuildContext context) {
    final dimmed = state != HomeModeCardState.enabled;

    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _interactive ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          splashColor: Colors.white24,
          highlightColor: Colors.white10,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, deepColor],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(compact ? 12 : 14),
              child: compact ? _compactBody() : _fullBody(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fullBody() {
    return Row(
      children: [
        _iconBox(40),
        AppSpacing.gapHMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: HomeTextStyles.title(color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (tag != null) ...[
                    const SizedBox(width: 6),
                    _pill(tag!),
                  ],
                  if (state == HomeModeCardState.comingSoon) ...[
                    const SizedBox(width: 6),
                    _pill(AppStringsBn.comingSoon),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: HomeTextStyles.caption(color: Colors.white.withValues(alpha: 0.9)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (meta != null) ...[
                const SizedBox(height: 2),
                Text(
                  meta!,
                  style: HomeTextStyles.caption(color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
        ),
      ],
    );
  }

  Widget _compactBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _iconBox(32),
            const Spacer(),
            if (state == HomeModeCardState.comingSoon)
              _pill(AppStringsBn.comingSoon),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: HomeTextStyles.body(color: Colors.white),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: HomeTextStyles.caption(color: Colors.white70),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (meta != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              meta!,
              style: HomeTextStyles.chip(color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _iconBox(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.55),
    );
  }

  Widget _pill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: HomeTextStyles.chip(color: Colors.white)),
    );
  }
}

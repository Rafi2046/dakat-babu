import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings_bn.dart';
import '../../../core/constants/home_text_styles.dart';

enum HomeNavTab { lobby, rank, role, badge, shop }

/// Home bottom navigation with deterministic selected tab.
class HomeBottomNav extends StatelessWidget {
  final HomeNavTab selected;
  final ValueChanged<HomeNavTab> onSelect;

  const HomeBottomNav({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.96),
        border: const Border(top: BorderSide(color: AppColors.glassBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              _item(HomeNavTab.lobby, Icons.home_rounded, AppStringsBn.navLobby),
              _item(HomeNavTab.rank, Icons.bar_chart_rounded, AppStringsBn.navRank),
              _item(HomeNavTab.role, Icons.badge_outlined, AppStringsBn.navRole),
              _item(HomeNavTab.badge, Icons.military_tech, AppStringsBn.navBadge),
              _item(HomeNavTab.shop, Icons.shopping_bag_outlined, AppStringsBn.navShop),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(HomeNavTab tab, IconData icon, String label) {
    final isSelected = selected == tab;
    final color = isSelected ? AppColors.homeFeatured : AppColors.textLightSecondary;

    return Expanded(
      child: InkWell(
        onTap: () => onSelect(tab),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                style: HomeTextStyles.nav(color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 4,
                child: isSelected
                    ? Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.homeFeatured,
                          shape: BoxShape.circle,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

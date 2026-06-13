import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/trail_constants.dart';

class JFBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const JFBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  static const List<_NavItem> _items = [
    _NavItem(
      iconInactive: Icons.menu_book_outlined,
      iconActive: Icons.menu_book_rounded,
      activeColor: Color(0xFF1CB0F6),
    ),
    _NavItem(
      iconInactive: Icons.emoji_events_outlined,
      iconActive: Icons.emoji_events_rounded,
      activeColor: Color(0xFFF59E0B),
    ),
    _NavItem(
      iconInactive: Icons.leaderboard_outlined,
      iconActive: Icons.leaderboard_rounded,
      activeColor: Color(0xFFD4A017),
    ),
    _NavItem(
      iconInactive: Icons.newspaper_outlined,
      iconActive: Icons.newspaper_rounded,
      activeColor: Color(0xFF58CC02),
    ),
    _NavItem(
      iconInactive: Icons.workspace_premium_outlined,
      iconActive: Icons.workspace_premium_rounded,
      activeColor: Color(0xFFCE82FF),
    ),
    _NavItem(
      iconInactive: Icons.person_outlined,
      iconActive: Icons.person_rounded,
      activeColor: Color(0xFF1CB0F6),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFFE8EDF2);
    final inactiveColor = isDark ? const Color(0xFF5A7A8A) : const Color(0xFFB0B8C1);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: TrailConstants.navBarHeight,
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final isSelected = currentIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onTabSelected(index);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? item.activeColor.withValues(alpha: isDark ? 0.18 : 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            isSelected ? item.iconActive : item.iconInactive,
                            size: TrailConstants.navIconSize,
                            color: isSelected ? item.activeColor : inactiveColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        // Active dot indicator
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isSelected ? TrailConstants.navDotSize : 0,
                          height: isSelected ? TrailConstants.navDotSize : 0,
                          decoration: BoxDecoration(
                            color: item.activeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData iconInactive;
  final IconData iconActive;
  final Color activeColor;

  const _NavItem({
    required this.iconInactive,
    required this.iconActive,
    this.activeColor = const Color(0xFF4A90E2),
  });
}

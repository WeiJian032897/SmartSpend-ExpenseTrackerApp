import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../l10n/app_localizations.dart';

class BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      elevation: 8,
      child: SizedBox(
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(context, 0, Icons.home_outlined, Icons.home, AppLocalizations.of(context)?.home ?? 'Home'),
            _buildNavItem(context, 1, Icons.bar_chart_outlined, Icons.bar_chart, AppLocalizations.of(context)?.statistic ?? 'Stats'),
            _buildNavItem(context, 2, Icons.pie_chart_outline, Icons.pie_chart, 'Charts'),
            _buildNavItem(context, 3, Icons.psychology_outlined, Icons.psychology, 'AI'),
            _buildNavItem(context, 4, Icons.calendar_today_outlined, Icons.calendar_today, AppLocalizations.of(context)?.planning ?? 'Plan'),
            _buildNavItem(context, 5, Icons.settings_outlined, Icons.settings, AppLocalizations.of(context)?.settings ?? 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, IconData activeIcon, String label) {
    final isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            color: isActive ? AppColors.primaryBlue : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? AppColors.primaryBlue : Colors.grey,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
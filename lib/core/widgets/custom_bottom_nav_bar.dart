import 'package:flutter/material.dart';

class CustomBottomNavBarItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  CustomBottomNavBarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

class CustomBottomNavBar extends StatelessWidget implements PreferredSizeWidget {
  final List<CustomBottomNavBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color selectedItemColor;
  final Color unselectedItemColor;

  const CustomBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.selectedItemColor = Colors.pink,
    this.unselectedItemColor = Colors.grey,
  });

  @override
  Size get preferredSize => const Size.fromHeight(100.0);

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    const double maxBarWidth = 480.0;
    final double barWidth = screenWidth > maxBarWidth ? maxBarWidth : screenWidth;
    const double horizontalMargin = 16.0;
    const double internalPadding = 8.0;
    
    // Calculate safe available width for navigation items
    final double availableWidth = barWidth - (horizontalMargin * 2) - (internalPadding * 2);
    final int totalItems = items.length;

    // Active item flex factor is 2.4, inactive is 1.0.
    // Total weight = activeFlex + (totalItems - 1) * inactiveFlex.
    final double activeFlex = 2.4;
    final double inactiveFlex = 1.0;
    final double totalWeight = activeFlex + (totalItems - 1) * inactiveFlex;

    final double inactiveWidth = availableWidth / totalWeight;
    final double activeWidth = inactiveWidth * activeFlex;

    return Container(
      height: 100.0,
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        bottom: true,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: barWidth - (horizontalMargin * 2),
            margin: const EdgeInsets.only(
              bottom: 8.0,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: internalPadding,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.pink.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(totalItems, (index) {
                final isSelected = index == currentIndex;
                final item = items[index];
                final displayIcon = isSelected ? (item.activeIcon ?? item.icon) : item.icon;

                return GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: isSelected ? activeWidth : inactiveWidth,
                    height: 48,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? selectedItemColor.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.none,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              displayIcon,
                              color: isSelected ? selectedItemColor : unselectedItemColor,
                              size: 24,
                            ),
                            ClipRect(
                              child: AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: isSelected
                                    ? Row(
                                        children: [
                                          const SizedBox(width: 6),
                                          Text(
                                            item.label,
                                            style: TextStyle(
                                              color: selectedItemColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

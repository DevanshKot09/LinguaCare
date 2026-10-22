import 'package:flutter/material.dart';
import 'breakpoints.dart';

class ResponsiveScaffoldItem {
  final String label;
  final IconData icon;
  final IconData? selectedIcon;

  const ResponsiveScaffoldItem({
    required this.label,
    required this.icon,
    this.selectedIcon,
  });
}

class ResponsiveScaffold extends StatelessWidget {
  final String title;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<ResponsiveScaffoldItem> items;
  final Widget body;
  final List<Widget>? actions;
  final Color? accentColor;

  const ResponsiveScaffold({
    super.key,
    required this.title,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.items,
    required this.body,
    this.actions,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final compact = isCompact(context);
    final theme = Theme.of(context);
    final effectiveAccent = accentColor ?? theme.colorScheme.primary;

    final navDestinations = items.map((item) {
      return NavigationDestination(
        icon: Icon(item.icon),
        selectedIcon: Icon(item.selectedIcon ?? item.icon),
        label: item.label,
      );
    }).toList();

    final railDestinations = items.map((item) {
      return NavigationRailDestination(
        icon: Icon(item.icon),
        selectedIcon: Icon(item.selectedIcon ?? item.icon),
        label: Text(item.label),
      );
    }).toList();

    if (compact) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: actions,
          backgroundColor: theme.colorScheme.surface,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: body,
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: navDestinations,
          indicatorColor: effectiveAccent.withValues(alpha: 0.2),
        ),
      );
    } else {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              destinations: railDestinations,
              backgroundColor: theme.colorScheme.surface,
              indicatorColor: effectiveAccent.withValues(alpha: 0.2),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: Scaffold(
                appBar: AppBar(
                  title: Text(title),
                  actions: actions,
                  backgroundColor: theme.colorScheme.surface,
                ),
                body: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: body,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}

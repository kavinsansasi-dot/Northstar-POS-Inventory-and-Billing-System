import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../providers/auth_provider.dart';

class Sidebar extends ConsumerStatefulWidget {
  const Sidebar({
    required this.selectedPath,
    required this.isAdmin,
    this.inDrawer = false,
    this.compactOnly = false,
    super.key,
  });

  final String selectedPath;
  final bool isAdmin;
  final bool inDrawer;
  final bool compactOnly;

  static const _items = [
    _NavItem('Overview', '/dashboard', Icons.grid_view_rounded, true),
    _NavItem('Billing', '/billing', Icons.point_of_sale_rounded, false),
    _NavItem('Products', '/products', Icons.inventory_2_outlined, false),
    _NavItem('Sales history', '/sales', Icons.receipt_long_outlined, false),
    _NavItem('Customers', '/customers', Icons.people_outline_rounded, false),
    _NavItem('Reports', '/reports', Icons.query_stats_rounded, true),
  ];

  static String titleFor(String path) {
    if (path.startsWith('/products')) return 'Products';
    if (path == '/invoice') return 'Invoice';
    return _items
            .where((item) => item.path == path)
            .map((item) => item.label)
            .firstOrNull ??
        'Workspace';
  }

  @override
  ConsumerState<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends ConsumerState<Sidebar> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final user = ref.watch(authProvider).user;
    final items = Sidebar._items
        .where((item) => widget.isAdmin || !item.adminOnly)
        .toList();
    final expanded = widget.inDrawer || (!widget.compactOnly && !_collapsed);

    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 180),
      width: widget.inDrawer
          ? double.infinity
          : expanded
          ? 260
          : 72,
      decoration: BoxDecoration(
        color: palette.surface,
        border: widget.inDrawer
            ? null
            : Border(right: BorderSide(color: palette.border)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: expanded ? 16 : 10,
        vertical: 18,
      ),
      child: Column(
        crossAxisAlignment: expanded
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.center,
        children: [
          if (expanded)
            Row(
              children: [
                _BrandMark(color: palette.primary),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Northstar',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'RETAIL WORKSPACE',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 0.8,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!widget.inDrawer && !widget.compactOnly)
                  IconButton(
                    tooltip: 'Collapse sidebar',
                    onPressed: () => setState(() => _collapsed = !_collapsed),
                    icon: Icon(
                      Icons.keyboard_double_arrow_left,
                      size: 20,
                      color: palette.textSecondary,
                    ),
                  ),
              ],
            )
          else
            Column(
              children: [
                _BrandMark(color: palette.primary),
                if (!widget.inDrawer && !widget.compactOnly)
                  IconButton(
                    tooltip: 'Expand sidebar',
                    onPressed: () => setState(() => _collapsed = !_collapsed),
                    icon: Icon(
                      Icons.keyboard_double_arrow_right,
                      size: 20,
                      color: palette.textSecondary,
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 34),
          if (expanded)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 10, bottom: 10),
                child: Text(
                  'WORKSPACE',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1,
                    color: palette.textSecondary,
                  ),
                ),
              ),
            ),
          for (final item in items)
            _NavigationItem(
              item: item,
              expanded: expanded,
              selected: _isSelected(item, widget.selectedPath),
              onTap: () {
                if (widget.inDrawer) Navigator.of(context).pop();
                context.go(item.path);
              },
            ),
          const Spacer(),
          if (expanded) ...[
            Divider(color: palette.border, height: 24),
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: palette.primarySoft,
                  child: Text(
                    (user?.name.isNotEmpty ?? false)
                        ? user!.name.substring(0, 1).toUpperCase()
                        : 'U',
                    style: TextStyle(
                      color: palette.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Team member',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user?.role.toUpperCase() ?? '',
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: palette.textSecondary),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Account options',
                  icon: Icon(Icons.more_horiz, color: palette.textSecondary),
                  onSelected: (value) {
                    if (value == 'theme') {
                      ThemeModeScope.maybeOf(context)?.toggle();
                    } else if (value == 'logout') {
                      ref.read(authProvider.notifier).logout();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'theme',
                      child: Text('Toggle appearance'),
                    ),
                    PopupMenuItem(value: 'logout', child: Text('Sign out')),
                  ],
                ),
              ],
            ),
          ] else ...[
            const Spacer(),
            IconButton(
              tooltip: 'Sign out',
              onPressed: () => ref.read(authProvider.notifier).logout(),
              icon: const Icon(Icons.logout_rounded),
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }

  bool _isSelected(_NavItem item, String path) =>
      item.path == path ||
      (item.path == '/products' && path.startsWith('/products'));
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 38,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [color, color.withValues(alpha: 0.74)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(13),
    ),
    child: const Icon(
      Icons.bubble_chart_rounded,
      color: Colors.white,
      size: 23,
    ),
  );
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.item,
    required this.expanded,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool expanded;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final foreground = selected ? palette.primary : palette.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Tooltip(
        message: expanded ? '' : item.label,
        child: Material(
          color: selected ? palette.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 46,
              child: Row(
                mainAxisAlignment: expanded
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  if (expanded) const SizedBox(width: 13),
                  Icon(item.icon, size: 20, color: foreground),
                  if (expanded) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: foreground,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (selected)
                      Container(
                        width: 3,
                        height: 20,
                        decoration: BoxDecoration(
                          color: palette.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    const SizedBox(width: 10),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.path, this.icon, this.adminOnly);
  final String label;
  final String path;
  final IconData icon;
  final bool adminOnly;
}

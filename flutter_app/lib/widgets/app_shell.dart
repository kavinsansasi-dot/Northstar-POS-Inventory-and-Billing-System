import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../providers/auth_provider.dart';
import 'design_system.dart';
import 'sidebar.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.child, required this.selectedPath, super.key});

  final Widget child;
  final String selectedPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.isAdmin ?? false;

    if (width < 700) {
      return _MobileShell(
        selectedPath: selectedPath,
        isAdmin: isAdmin,
        child: child,
      );
    }

    if (width < 1000) {
      return Scaffold(
        backgroundColor: context.palette.background,
        body: Row(
          children: [
            Sidebar(
              selectedPath: selectedPath,
              isAdmin: isAdmin,
              compactOnly: true,
            ),
            Expanded(
              child: Column(
                children: [
                  _TopBar(
                    title: Sidebar.titleFor(selectedPath),
                    userName: user?.name ?? '',
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.palette.background,
      body: Row(
        children: [
          Sidebar(selectedPath: selectedPath, isAdmin: isAdmin),
          Expanded(
            child: Column(
              children: [
                _TopBar(
                  title: Sidebar.titleFor(selectedPath),
                  userName: user?.name ?? '',
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileShell extends StatelessWidget {
  const _MobileShell({
    required this.child,
    required this.selectedPath,
    required this.isAdmin,
  });

  final Widget child;
  final String selectedPath;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final destinations = <_Destination>[
      if (isAdmin)
        const _Destination('Overview', '/dashboard', Icons.grid_view_rounded),
      const _Destination('Billing', '/billing', Icons.point_of_sale_rounded),
      const _Destination('Products', '/products', Icons.inventory_2_outlined),
      const _Destination('Sales', '/sales', Icons.receipt_long_outlined),
    ];
    var selectedIndex = destinations.indexWhere(
      (item) => item.path == selectedPath,
    );
    if (selectedIndex < 0 && selectedPath.startsWith('/products')) {
      selectedIndex = destinations.indexWhere(
        (item) => item.path == '/products',
      );
    }
    if (selectedIndex < 0) selectedIndex = 0;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        titleSpacing: 0,
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: 'Open navigation',
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(Sidebar.titleFor(selectedPath)),
        actions: [const _ThemeToggleButton(), const SizedBox(width: 8)],
      ),
      drawer: Drawer(
        width: 290,
        child: Sidebar(
          selectedPath: selectedPath,
          isAdmin: isAdmin,
          inDrawer: true,
        ),
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          final destination = destinations[index];
          if (destination.path != selectedPath) {
            context.go(destination.path);
          }
        },
        destinations: [
          for (final destination in destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}

class _TopBar extends StatefulWidget {
  const _TopBar({required this.title, required this.userName});

  final String title;
  final String userName;

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final screenWidth = MediaQuery.sizeOf(context).width;
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      padding: EdgeInsets.symmetric(horizontal: screenWidth < 1200 ? 16 : 28),
      child: Row(
        children: [
          Flexible(
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (screenWidth >= 1200) ...[
            const SizedBox(width: 28),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: SearchBarField(
                    controller: _searchController,
                    hint: 'Search your workspace',
                    onChanged: (_) {},
                  ),
                ),
              ),
            ),
          ] else ...[
            const Spacer(),
          ],
          const _ThemeToggleButton(),
          SizedBox(width: screenWidth < 1200 ? 8 : 14),
          CircleAvatar(
            radius: 18,
            backgroundColor: palette.primarySoft,
            child: Text(
              widget.userName.isNotEmpty
                  ? widget.userName.substring(0, 1).toUpperCase()
                  : 'U',
              style: TextStyle(
                color: palette.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: isDark
          ? 'Switch to light appearance'
          : 'Switch to dark appearance',
      onPressed: () => ThemeModeScope.maybeOf(context)?.toggle(),
      icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
    );
  }
}

class _Destination {
  const _Destination(this.label, this.path, this.icon);
  final String label;
  final String path;
  final IconData icon;
}

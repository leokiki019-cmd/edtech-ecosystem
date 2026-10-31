import 'package:edtech_app/auth/auth_provider.dart';
import 'package:edtech_app/auth/login_screen.dart';
import 'package:edtech_app/auth/signup_screen.dart';
import 'package:edtech_app/auth/verify_sms_screen.dart';
import 'package:edtech_app/screens/calendar_screen.dart';
import 'package:edtech_app/screens/chat_screen.dart';
import 'package:edtech_app/screens/courses_screen.dart';
import 'package:edtech_app/screens/dashboard_screen.dart';
import 'package:edtech_app/screens/integrity_screen.dart';
import 'package:edtech_app/theme.dart';
import 'package:edtech_app/widgets/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class EdTechApp extends StatefulWidget {
  const EdTechApp({super.key});

  @override
  State<EdTechApp> createState() => _EdTechAppState();
}

class _EdTechAppState extends State<EdTechApp> {
  late final GoRouter _router = GoRouter(
    refreshListenable: context.read<AuthProvider>(),
    redirect: (context, state) {
      final auth = context.read<AuthProvider>();
      final loggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/verify-sms';

      if (!auth.isAuthenticated && !loggingIn) {
        return '/login';
      }
      if (auth.isAuthenticated && loggingIn) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const ResponsiveShell()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
      GoRoute(
        path: '/verify-sms',
        builder: (context, state) => const VerifySmsScreen(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: 'EdTech Ecosystem',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      builder: (context, child) => _PageTransitionHost(child: child ?? const SizedBox()),
    );
  }
}

/// Wraps routed pages in a soft fade + slide-up so switching between
/// login / dashboard feels like it "pops in".
class _PageTransitionHost extends StatelessWidget {
  final Widget child;

  const _PageTransitionHost({required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (widget, animation) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: widget,
          ),
        );
      },
      child: child,
    );
  }
}

class ResponsiveShell extends StatefulWidget {
  const ResponsiveShell({super.key});

  @override
  State<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends State<ResponsiveShell> {
  int _index = 0;

  static final List<Widget> _screens = <Widget>[
    const DashboardScreen(),
    const CoursesScreen(),
    const CalendarScreen(),
    const ChatScreen(),
    const IntegrityScreen(),
  ];

  static const List<String> _titles = <String>[
    'Dashboard',
    'Courses',
    'Calendar',
    'Chat',
    'Integrity',
  ];

  static const List<IconData> _icons = <IconData>[
    Icons.dashboard_rounded,
    Icons.school_rounded,
    Icons.calendar_month_rounded,
    Icons.chat_bubble_rounded,
    Icons.verified_rounded,
  ];

  void _selectTab(int index) {
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;
    final isTablet = width >= 600 && width < 900;
    final showRail = isDesktop || isTablet;

    final List<Widget> children = <Widget>[];

    if (showRail) {
      children.add(
        NavigationRail(
          selectedIndex: _index,
          onDestinationSelected: _selectTab,
          labelType: NavigationRailLabelType.all,
          backgroundColor: kSurface,
          leading: const SizedBox(
            height: 70,
            child: DrawerHeader(
              decoration: BoxDecoration(
                gradient: candyGradient,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.school_rounded, color: kPrimary),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'EdTech',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          trailing: Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: IconButton(
                  tooltip: 'Sign out',
                  icon: const Icon(Icons.logout_rounded, color: kTextSecondary),
                  onPressed: () => context.read<AuthProvider>().logout(),
                ),
              ),
            ),
          ),
          destinations: List.generate(
            _titles.length,
            (index) => NavigationRailDestination(
              icon: Icon(_icons[index], color: kTextSecondary),
              selectedIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kTabColors[index % kTabColors.length],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_icons[index], color: Colors.white, size: 22),
              ),
              label: Text(_titles[index]),
            ),
          ),
        ),
      );
    }

    children.add(
      Expanded(
        // AnimatedSwitcher gives a gentle cross-fade between tabs.
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (widget, animation) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.03, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: widget,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey(_index),
            child: _screens[_index],
          ),
        ),
      ),
    );

    return Scaffold(
      key: _scaffoldKey,
      appBar: showRail
          ? null
          : AppBar(
              title: const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: kPrimary,
                    child: Icon(Icons.school_rounded, color: Colors.white, size: 20),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'EdTech',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                  icon: const Icon(Icons.menu_rounded),
                ),
              ],
            ),
      drawer: showRail
          ? null
          : AppDrawer(
              selectedIndex: _index,
              onSelect: _selectTab,
            ),
      body: Row(
        children: children,
      ),
      bottomNavigationBar: showRail
          ? null
          : BottomNav(
              selectedIndex: _index,
              onTap: _selectTab,
            ),
    );
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
}

class AppDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const AppDrawer({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  static const _items = [
    _DrawerItemData(Icons.dashboard_rounded, 'Dashboard', 'Overview of your week'),
    _DrawerItemData(Icons.school_rounded, 'Courses', 'Enrolled classes & assignments'),
    _DrawerItemData(Icons.calendar_month_rounded, 'Calendar', 'Deadlines & events'),
    _DrawerItemData(Icons.chat_bubble_rounded, 'Chat', 'Classroom discussion'),
    _DrawerItemData(Icons.verified_rounded, 'Integrity', 'Effort & authenticity score'),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Drawer(
      child: Container(
        color: kSurface,
        child: Column(
          children: [
            _DrawerHeader(
              name: user?.displayName ?? 'Student',
              subtitle: user == null
                  ? 'Not signed in'
                  : '${user.role[0].toUpperCase()}${user.role.substring(1)}'
                      '${user.courseIds.isNotEmpty ? ' · ${user.courseIds.length} course${user.courseIds.length == 1 ? '' : 's'}' : ''}',
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (var index = 0; index < _items.length; index++)
                    _DrawerItem(
                      icon: _items[index].icon,
                      title: _items[index].title,
                      subtitle: _items[index].subtitle,
                      color: kTabColors[index % kTabColors.length],
                      selected: selectedIndex == index,
                      onTap: () {
                        onSelect(index);
                        Navigator.of(context).pop();
                      },
                    ),
                  const Divider(height: 32),
                  _DrawerItem(
                    icon: Icons.logout_rounded,
                    title: 'Sign out',
                    subtitle: 'Leave the session',
                    color: kError,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.read<AuthProvider>().logout();
                    },
                  ),
                ],
              ),
            ),
            const _DrawerFooter(),
          ],
        ),
      ),
    );
  }
}

class _DrawerItemData {
  final IconData icon;
  final String title;
  final String subtitle;

  const _DrawerItemData(this.icon, this.title, this.subtitle);
}

class _DrawerHeader extends StatelessWidget {
  final String name;
  final String subtitle;

  const _DrawerHeader({required this.name, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 128,
      decoration: const BoxDecoration(
        gradient: candyGradient,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white,
              child: Icon(Icons.school_rounded, color: kPrimary),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: selected ? tintOf(color, 0.08) : Colors.transparent,
      ),
      child: ListTile(
        leading: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: selected ? color : tintOf(color, 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: selected ? Colors.white : color, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: kTextPrimary,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: kTextSecondary,
            fontSize: 11,
          ),
        ),
        trailing: selected
            ? Icon(Icons.chevron_right_rounded, color: color, size: 18)
            : null,
        dense: true,
        onTap: onTap,
      ),
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  const _DrawerFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: kSurface,
        border: Border(top: BorderSide(color: kBorder)),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.build_rounded, color: kTextSecondary, size: 20),
            title: Text(
              'App version',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: kTextPrimary,
              ),
            ),
            subtitle: Text(
              '0.2.0+2',
              style: TextStyle(color: kTextSecondary, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:edtech_app/screens/calendar_screen.dart';
import 'package:edtech_app/screens/chat_screen.dart';
import 'package:edtech_app/screens/courses_screen.dart';
import 'package:edtech_app/screens/dashboard_screen.dart';
import 'package:edtech_app/screens/integrity_screen.dart';
import 'package:edtech_app/theme.dart';
import 'package:edtech_app/widgets/bottom_nav.dart';
import 'package:flutter/material.dart';

class EdTechApp extends StatelessWidget {
  const EdTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EdTech Ecosystem',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static final List<Widget> _screens = <Widget>[
    DashboardScreen(),
    CoursesScreen(),
    CalendarScreen(),
    ChatScreen(),
    IntegrityScreen(),
  ];

  static const List<String> _titles = <String>[
    'Dashboard',
    'Courses',
    'Calendar',
    'Chat',
    'Integrity',
  ];

  void _toggleDrawer() => _scaffoldKey.currentState?.openDrawer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              radius: 14,
              backgroundColor: kPrimary,
              child: Icon(Icons.person, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(
              _titles[_index],
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
        leading: IconButton(
          onPressed: _toggleDrawer,
          icon: const Icon(Icons.menu),
          tooltip: 'Open menu',
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _screens[_index],
      bottomNavigationBar: BottomNav(
        selectedIndex: _index,
        onTap: (value) => setState(() => _index = value),
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: kSurface,
        child: Column(
          children: [
            _DrawerHeader(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: const [
                  _DrawerItem(
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                    subtitle: 'Overview of your week',
                  ),
                  _DrawerItem(
                    icon: Icons.school,
                    title: 'Courses',
                    subtitle: 'Enrolled classes & assignments',
                  ),
                  _DrawerItem(
                    icon: Icons.calendar_today,
                    title: 'Calendar',
                    subtitle: 'Deadlines & events',
                  ),
                  _DrawerItem(
                    icon: Icons.chat_bubble_outline,
                    title: 'Chat',
                    subtitle: 'Classroom discussion',
                  ),
                  _DrawerItem(
                    icon: Icons.verified,
                    title: 'Integrity',
                    subtitle: 'Effort & authenticity score',
                  ),
                  Divider(height: 32),
                  _DrawerItem(
                    icon: Icons.settings,
                    title: 'Settings',
                    subtitle: 'Account & preferences',
                  ),
                  _DrawerItem(
                    icon: Icons.logout,
                    title: 'Sign out',
                    subtitle: 'Leave the session',
                  ),
                ],
              ),
            ),
            _DrawerFooter(),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: livelyGradient(kPrimary, kPrimaryDark),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const CircleAvatar(
              radius: 26,
              backgroundColor: kPrimary,
              child: Icon(Icons.person, size: 26, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              'Alex Rivera',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const Text(
              'Student · CS 301',
              style: TextStyle(
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

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: kBorder.withOpacity(0.5)),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: kBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: kTextSecondary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
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
        dense: true,
      ),
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurface,
        border: Border(
          top: BorderSide(color: kBorder),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.build, color: kTextSecondary, size: 20),
            title: const Text(
              'App version',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
            subtitle: const Text('0.1.0+1', style: TextStyle(color: kTextSecondary, fontSize: 11)),
            trailing: const Icon(Icons.chevron_right, color: kTextSecondary, size: 18),
          ),
        ],
      ),
    );
  }
}

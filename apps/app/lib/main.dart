import 'package:flutter/material.dart';

void main() {
  runApp(const EdTechApp());
}

class EdTechApp extends StatelessWidget {
  const EdTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EdTech Ecosystem',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
      ),
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

  static const _pages = <Widget>[
    DashboardPage(),
    CoursesPage(),
    CalendarPage(),
    ChatPage(),
    IntegrityPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EdTech Ecosystem'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(child: Text('AR')),
          ),
        ],
      ),
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Courses',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.verified_outlined),
            selectedIcon: Icon(Icons.verified),
            label: 'Integrity',
          ),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Good morning, Alex',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Fall 2026 · CS 301 Human-Computer Interaction',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
        ),
        const SizedBox(height: 20),
        Row(
          children: const [
            Expanded(
              child: _MetricCard(
                label: 'Open tasks',
                value: '3',
                icon: Icons.assignment_outlined,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'Avg. effort',
                value: '84',
                icon: Icons.insights_outlined,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'Due this week',
                value: '2',
                icon: Icons.schedule_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Upcoming deadlines',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        const _DeadlineCard(
          title: 'Prototype Critique',
          course: 'CS 301',
          due: 'In 3 days',
          urgency: Colors.orange,
        ),
        const SizedBox(height: 10),
        const _DeadlineCard(
          title: 'Usability Study Report',
          course: 'CS 301',
          due: 'In 7 days',
          urgency: Colors.blue,
        ),
        const SizedBox(height: 10),
        const _DeadlineCard(
          title: 'Heuristics quiz',
          course: 'CS 301',
          due: 'In 5 days',
          urgency: Colors.purple,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF2563EB)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeadlineCard extends StatelessWidget {
  const _DeadlineCard({
    required this.title,
    required this.course,
    required this.due,
    required this.urgency,
  });

  final String title;
  final String course;
  final String due;
  final Color urgency;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: urgency.withOpacity(0.12),
          child: Icon(Icons.assignment, color: urgency, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(course),
        trailing: Text(
          due,
          style: TextStyle(color: urgency, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class CoursesPage extends StatelessWidget {
  const CoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        _CourseCard(
          code: 'CS 301',
          title: 'Human-Computer Interaction',
          teacher: 'Dr. Maya Chen',
          students: 3,
          assignments: 4,
          color: Color(0xFF2563EB),
        ),
        SizedBox(height: 12),
        _CourseCard(
          code: 'CS 210',
          title: 'Data Structures',
          teacher: 'Prof. Daniel Kim',
          students: 42,
          assignments: 6,
          color: Color(0xFF7C3AED),
        ),
        SizedBox(height: 12),
        _CourseCard(
          code: 'DES 150',
          title: 'Design Foundations',
          teacher: 'Prof. Elena Rossi',
          students: 28,
          assignments: 3,
          color: Color(0xFF0F766E),
        ),
      ],
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.code,
    required this.title,
    required this.teacher,
    required this.students,
    required this.assignments,
    required this.color,
  });

  final String code;
  final String title;
  final String teacher;
  final int students;
  final int assignments;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    code,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.more_horiz, color: Colors.black38),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(teacher, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 14),
            Row(
              children: [
                _CourseStat(icon: Icons.people_outline, value: '$students'),
                const SizedBox(width: 18),
                _CourseStat(
                  icon: Icons.assignment_outlined,
                  value: '$assignments',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseStat extends StatelessWidget {
  const _CourseStat({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.black45),
        const SizedBox(width: 6),
        Text(value, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        _CalendarEntry(
          time: 'Tue · 10:00',
          title: 'Studio session',
          kind: 'Class · CS 301',
          color: Color(0xFF2563EB),
        ),
        _CalendarEntry(
          time: 'Thu · 23:59',
          title: 'Prototype Critique due',
          kind: 'Assignment · CS 301',
          color: Color(0xFFF59E0B),
        ),
        _CalendarEntry(
          time: 'Fri · 09:00',
          title: 'Heuristics quiz',
          kind: 'Quiz · CS 301',
          color: Color(0xFF7C3AED),
        ),
        _CalendarEntry(
          time: 'Next Wed · 23:59',
          title: 'Usability Study Report due',
          kind: 'Assignment · CS 301',
          color: Color(0xFFF59E0B),
        ),
        _CalendarEntry(
          time: 'In 10 days',
          title: 'Research symposium',
          kind: 'Institution',
          color: Color(0xFF0F766E),
        ),
      ],
    );
  }
}

class _CalendarEntry extends StatelessWidget {
  const _CalendarEntry({
    required this.time,
    required this.title,
    required this.kind,
    required this.color,
  });

  final String time;
  final String title;
  final String kind;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(time, style: const TextStyle(fontSize: 12, color: Colors.black45)),
                  const SizedBox(height: 2),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(kind, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        _ChannelTile(
          name: 'Announcements',
          lastMessage: 'Reminder: the usability study report is due next week.',
          icon: Icons.campaign_outlined,
          unread: 2,
        ),
        SizedBox(height: 10),
        _ChannelTile(
          name: 'Studio Discussion',
          lastMessage: 'Sharing my participant consent template for anyone who needs one.',
          icon: Icons.forum_outlined,
          unread: 0,
        ),
        SizedBox(height: 10),
        _ChannelTile(
          name: 'Project Team · Red',
          lastMessage: 'Priya: I can take the findings synthesis.',
          icon: Icons.groups_outlined,
          unread: 4,
        ),
      ],
    );
  }
}

class _ChannelTile extends StatelessWidget {
  const _ChannelTile({
    required this.name,
    required this.lastMessage,
    required this.icon,
    required this.unread,
  });

  final String name;
  final String lastMessage;
  final IconData icon;
  final int unread;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
          child: Icon(icon, color: const Color(0xFF2563EB)),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: unread > 0
            ? CircleAvatar(
                radius: 10,
                backgroundColor: const Color(0xFF2563EB),
                child: Text(
                  '$unread',
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              )
            : null,
      ),
    );
  }
}

class IntegrityPage extends StatelessWidget {
  const IntegrityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          elevation: 0,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'Current session effort',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 8),
                const Text(
                  '84',
                  style: TextStyle(fontSize: 56, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: const LinearProgressIndicator(
                    value: 0.84,
                    minHeight: 10,
                    backgroundColor: Color(0xFFE5E7EB),
                    color: Color(0xFF22C55E),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Organic drafting detected',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Keystrokes',
                value: '1,284',
                icon: Icons.keyboard_outlined,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'Pastes',
                value: '3',
                icon: Icons.content_paste_outlined,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'AI switches',
                value: '0',
                icon: Icons.tab_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Privacy note',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 6),
                Text(
                  'Only typing cadence, paste volume and tab activity are recorded. '
                  'Keystroke content and password fields are never captured.',
                  style: TextStyle(color: Colors.black54, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:edtech_app/auth/auth_provider.dart';
import 'package:edtech_app/auth/login_screen.dart';
import 'package:edtech_app/auth/signup_screen.dart';
import 'package:edtech_app/auth/verify_sms_screen.dart';
import 'package:edtech_app/screens/attendance_screen.dart';
import 'package:edtech_app/screens/calendar_screen.dart';
import 'package:edtech_app/screens/chat_screen.dart';
import 'package:edtech_app/screens/courses_screen.dart';
import 'package:edtech_app/screens/department_management_screen.dart';
import 'package:edtech_app/screens/integrity_screen.dart';
import 'package:edtech_app/screens/notes_screen.dart';
import 'package:edtech_app/screens/student_management_screen.dart';
import 'package:edtech_app/services/api_service.dart';
import 'package:edtech_app/theme.dart';
import 'package:edtech_app/widgets/swipeable_tabs.dart';
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
      GoRoute(path: '/', builder: (context, state) => const SwipeableShell()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
      GoRoute(
        path: '/verify-sms',
        builder: (context, state) => const VerifySmsScreen(),
      ),
      GoRoute(
        path: '/students',
        builder: (context, state) => const StudentManagementScreen(),
      ),
      GoRoute(
        path: '/departments',
        builder: (context, state) => const DepartmentManagementScreen(),
      ),
      GoRoute(
        path: '/attendance',
        builder: (context, state) => const AttendanceScreen(),
      ),
      GoRoute(
        path: '/notes',
        builder: (context, state) => const NotesScreen(),
      ),
    ],
  );

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    ApiService.instance.token = auth.token;
    auth.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    ApiService.instance.token = context.read<AuthProvider>().token;
  }

  @override
  void dispose() {
    context.read<AuthProvider>().removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: 'EdTech Ecosystem',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
    );
  }
}

import 'package:edtech_app/app.dart';
import 'package:edtech_app/auth/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthProvider();
  await auth.init();
  runApp(
    ChangeNotifierProvider(
      create: (_) => auth,
      child: const EdTechApp(),
    ),
  );
}

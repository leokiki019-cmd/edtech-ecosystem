import 'package:edtech_app/app.dart';
import 'package:edtech_app/auth/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const EdTechApp(),
    ),
  );
}

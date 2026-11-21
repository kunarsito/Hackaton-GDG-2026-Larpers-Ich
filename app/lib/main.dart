import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/main_layout.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FaroDevCampusApp());
}

class FaroDevCampusApp extends StatelessWidget {
  const FaroDevCampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FARO_DEV // CAMPUS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const MainLayout(),
    );
  }
}

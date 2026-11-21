import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_layout.dart';
import 'services/api_service.dart';

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
      home: const AuthGate(),
    );
  }
}

/// Muestra el login o la app según haya sesión guardada.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final ApiService _api = ApiService();
  bool _checking = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _api.restoreSession().then((ok) {
      if (mounted) {
        setState(() {
          _loggedIn = ok;
          _checking = false;
        });
      }
    });
  }

  Future<void> _logout() async {
    await _api.logout();
    if (mounted) setState(() => _loggedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: AppTheme.solderMask,
        body: Center(child: CircularProgressIndicator(color: AppTheme.phosphorGreen)),
      );
    }
    if (!_loggedIn) {
      return LoginScreen(onLoggedIn: () => setState(() => _loggedIn = true));
    }
    return MainLayout(onLogout: _logout);
  }
}

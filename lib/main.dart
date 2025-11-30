import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_page.dart';
import 'login_page.dart';
import 'pages/onboarding_page.dart';
import 'services/auth_service.dart';

import 'services/theme_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();

    return ListenableBuilder(
      listenable: themeService,
      builder: (context, child) {
        return MaterialApp(
          title: 'Edu Markaz',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: themeService.themeMode,
          home: AuthChecker(themeService: themeService),
        );
      },
    );
  }
}

class AuthChecker extends StatefulWidget {
  final ThemeService? themeService;

  const AuthChecker({super.key, this.themeService});

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  final _authService = AuthService();
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _onboardingCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_completed') ?? false;
    final isLoggedIn = await _authService.isLoggedIn();

    setState(() {
      _onboardingCompleted = onboardingDone;
      _isAuthenticated = isLoggedIn;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show onboarding if not completed
    if (!_onboardingCompleted) {
      return const OnboardingPage();
    }

    // Show home or login based on authentication
    return _isAuthenticated
        ? HomePage(themeService: widget.themeService)
        : const LoginPage();
  }
}

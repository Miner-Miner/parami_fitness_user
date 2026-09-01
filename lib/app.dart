import 'package:flutter/material.dart';

import 'models/gym_models.dart';
import 'models/connection_settings.dart';
import 'screens/gym_shell.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/gym_api.dart';
import 'services/connection_settings_store.dart';
import 'services/session_store.dart';
import 'ui/app_theme.dart';

class ParamiFitnessApp extends StatefulWidget {
  const ParamiFitnessApp({super.key});

  @override
  State<ParamiFitnessApp> createState() => _ParamiFitnessAppState();
}

class _ParamiFitnessAppState extends State<ParamiFitnessApp> {
  final SessionStore _sessionStore = SessionStore();
  final ConnectionSettingsStore _connectionStore = ConnectionSettingsStore();

  AuthSession? _session;
  ConnectionSettings _connectionSettings = ConnectionSettings.defaults();
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final results = await Future.wait<Object?>([
      _sessionStore.read(),
      _connectionStore.read(),
    ]);
    final storedSession = results[0] as AuthSession?;
    final storedSettings = results[1] as ConnectionSettings;
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!mounted) {
      return;
    }
    setState(() {
      _session = storedSession;
      _connectionSettings = storedSettings;
      _initializing = false;
    });
  }

  GymApi get _api => GymApi(
    baseUrl: _connectionSettings.baseUrl,
    database: _connectionSettings.database,
  );

  Future<void> _handleLogin(AuthSession session) async {
    await _sessionStore.save(session);
    if (!mounted) {
      return;
    }
    setState(() {
      _session = session;
    });
  }

  Future<void> _handleConnectionSettingsChanged(
    ConnectionSettings settings,
  ) async {
    await _connectionStore.save(settings);
    if (!mounted) {
      return;
    }
    setState(() {
      _connectionSettings = settings;
    });
  }

  Future<void> _handleLogout() async {
    await _sessionStore.clear();
    if (!mounted) {
      return;
    }
    setState(() {
      _session = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Parami Fitness',
      theme: gymTheme(),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: _initializing
            ? const SplashScreen(key: ValueKey('splash'))
            : _session == null
            ? LoginScreen(
                key: const ValueKey('login'),
                api: _api,
                connectionSettings: _connectionSettings,
                onConnectionSettingsChanged: _handleConnectionSettingsChanged,
                onLoggedIn: _handleLogin,
              )
            : GymShell(
                key: const ValueKey('shell'),
                api: _api,
                session: _session!,
                onLogout: _handleLogout,
              ),
      ),
    );
  }
}

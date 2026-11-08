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
import 'ui/appearance.dart';

class ParamiFitnessApp extends StatefulWidget {
  const ParamiFitnessApp({super.key});

  @override
  State<ParamiFitnessApp> createState() => _ParamiFitnessAppState();
}

class _ParamiFitnessAppState extends State<ParamiFitnessApp> {
  final AppearanceController _appearance = AppearanceController();

  final SessionStore _sessionStore = SessionStore();
  final ConnectionSettingsStore _connectionStore = ConnectionSettingsStore();

  AuthSession? _session;
  ConnectionSettings? _connectionSettings;
  String? _startupError;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
    _appearance.restore();
  }

  Future<void> _restoreSession() async {
    setState(() {
      _initializing = true;
      _startupError = null;
    });
    try {
      final settings = await _connectionStore.fetch();
      final previous = await _connectionStore.read();
      final sameConnection =
          previous?.normalizedBaseUrl == settings.normalizedBaseUrl &&
          previous?.database == settings.database;
      // A session belongs to one server/database and must not cross environments.
      if (!sameConnection) await _sessionStore.clear();
      final session = sameConnection ? await _sessionStore.read() : null;
      await _connectionStore.save(settings);
      if (!mounted) return;
      setState(() {
        _session = session;
        _connectionSettings = settings;
        _initializing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _startupError =
            'Unable to load app configuration. Check your connection and try again.';
      });
    }
  }

  GymApi get _api => GymApi(
    baseUrl: _connectionSettings!.baseUrl,
    database: _connectionSettings!.database,
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
  void dispose() {
    _appearance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppearanceScope(
      controller: _appearance,
      child: AnimatedBuilder(
        animation: _appearance,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Parami Fitness',
          theme: gymTheme(theme: _appearance.theme),
          darkTheme: gymTheme(theme: _appearance.theme, dark: true),
          themeMode: _appearance.dark ? ThemeMode.dark : ThemeMode.light,
          home: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: _initializing
                ? const SplashScreen(key: ValueKey('splash'))
                : _startupError != null
                ? Scaffold(
                    body: SafeArea(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_startupError!, textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: _restoreSession,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : _session == null
                ? LoginScreen(
                    key: const ValueKey('login'),
                    api: _api,
                    connectionSettings: _connectionSettings!,
                    onConnectionSettingsChanged:
                        _handleConnectionSettingsChanged,
                    onLoggedIn: _handleLogin,
                  )
                : GymShell(
                    key: const ValueKey('shell'),
                    api: _api,
                    session: _session!,
                    onLogout: _handleLogout,
                  ),
          ),
        ),
      ),
    );
  }
}

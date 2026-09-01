import 'package:flutter/material.dart';

import '../models/gym_models.dart';
import '../services/gym_api.dart';
import 'classes_screen.dart';
import 'home_dashboard.dart';
import 'profile_screen.dart';
import 'qr_screen.dart';

class GymShell extends StatefulWidget {
  const GymShell({
    super.key,
    required this.api,
    required this.session,
    required this.onLogout,
  });

  final GymApi api;
  final AuthSession session;
  final Future<void> Function() onLogout;

  @override
  State<GymShell> createState() => _GymShellState();
}

class _GymShellState extends State<GymShell> {
  int _currentIndex = 0;
  bool _expiryDialogVisible = false;

  late final List<Widget> _tabs = <Widget>[
    HomeDashboard(session: widget.session),
    ClassesScreen(api: widget.api, session: widget.session),
    QrScreen(api: widget.api, session: widget.session),
    ProfileScreen(
      api: widget.api,
      session: widget.session,
      onLogout: widget.onLogout,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowExpiryAlert();
    });
  }

  Future<void> _maybeShowExpiryAlert() async {
    if (!mounted || _expiryDialogVisible) {
      return;
    }
    setState(() {
      _expiryDialogVisible = true;
    });

    try {
      final nearest = await widget.api.nearestExpiry(widget.session);
      if (!mounted || nearest == null) {
        return;
      }
      final today = DateUtils.dateOnly(DateTime.now());
      final expiry = nearest.expirationDate;
      final daysRemaining = expiry?.difference(today).inDays;
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) {
          final title = daysRemaining != null && daysRemaining < 0
              ? 'Package expired'
              : 'Package reminder';
          final message = daysRemaining == null
              ? 'Your package is approaching its expiry window.'
              : daysRemaining < 0
              ? 'Your package expired ${daysRemaining.abs()} day(s) ago.'
              : 'Your package expires in $daysRemaining day(s).';
          return AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nearest.productName),
                const SizedBox(height: 8),
                Text(message),
                const SizedBox(height: 8),
                Text(
                  'Remaining sessions: ${nearest.remainingSessions}/${nearest.totalSessions}',
                ),
                if (expiry != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Expiry date: ${expiry.toLocal().toIso8601String().split('T').first}',
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (_) {
      // Informational popup only.
    } finally {
      if (mounted) {
        setState(() {
          _expiryDialogVisible = false;
        });
      }
    }
  }

  void _selectIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 0) {
      _maybeShowExpiryAlert();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _selectIndex,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.sports_gymnastics_rounded),
            label: 'Classes',
          ),
          NavigationDestination(icon: Icon(Icons.qr_code_rounded), label: 'QR'),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/gym_models.dart';
import '../services/gym_api.dart';
import '../ui/app_theme.dart';
import '../ui/appearance.dart';
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
                SizedBox(height: 8),
                Text(message),
                SizedBox(height: 8),
                Text(
                  'Remaining sessions: ${nearest.remainingSessions}/${nearest.totalSessions}',
                ),
                if (expiry != null) ...[
                  SizedBox(height: 8),
                  Text(
                    'Expiry date: ${expiry.toLocal().toIso8601String().split('T').first}',
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
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
    final theme = AppColors.of(context).variant;
    const destinations = [
      (Icons.home_rounded, 'Home'),
      (Icons.sports_gymnastics_rounded, 'Classes'),
      (Icons.qr_code_rounded, 'QR'),
      (Icons.person_rounded, 'Profile'),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('PARAMI'),
        actions: const [AppearanceControls(onDark: true)],
      ),
      drawer: theme == MemberTheme.roseGold
          ? Drawer(
              child: SafeArea(
                child: ListView(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Member workspace'),
                    ),
                    for (var i = 0; i < destinations.length; i++)
                      ListTile(
                        leading: Icon(destinations[i].$1),
                        title: Text(destinations[i].$2),
                        selected: _currentIndex == i,
                        onTap: () {
                          Navigator.pop(context);
                          _selectIndex(i);
                        },
                      ),
                  ],
                ),
              ),
            )
          : null,
      body: Row(
        children: [
          if (theme == MemberTheme.gold)
            LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: NavigationRail(
                      minWidth: 64,
                      extended: MediaQuery.sizeOf(context).width >= 900,
                      selectedIndex: _currentIndex,
                      onDestinationSelected: _selectIndex,
                      destinations: [
                        for (final item in destinations)
                          NavigationRailDestination(
                            icon: Icon(item.$1),
                            label: Text(item.$2),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            key: const ValueKey('member-pages'),
            child: IndexedStack(index: _currentIndex, children: _tabs),
          ),
        ],
      ),
      bottomNavigationBar: theme == MemberTheme.monochrome
          ? NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: _selectIndex,
              destinations: [
                for (final item in destinations)
                  NavigationDestination(icon: Icon(item.$1), label: item.$2),
              ],
            )
          : null,
    );
  }
}

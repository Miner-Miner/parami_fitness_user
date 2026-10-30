import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class AppearanceController extends ChangeNotifier {
  MemberTheme theme = MemberTheme.monochrome;
  bool dark = false;
  bool _disposed = false;
  bool _changed = false;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (_disposed || _changed) return;
    theme = MemberTheme.values.firstWhere(
      (value) => value.name == prefs.getString('member_theme'),
      orElse: () => MemberTheme.monochrome,
    );
    dark = prefs.getBool('member_dark_mode') ?? false;
    notifyListeners();
  }

  Future<void> select({MemberTheme? theme, bool? dark}) async {
    _changed = true;
    final prefs = await SharedPreferences.getInstance();
    if (theme != null && !await prefs.setString('member_theme', theme.name)) {
      throw StateError('Could not save theme');
    }
    if (dark != null && !await prefs.setBool('member_dark_mode', dark)) {
      throw StateError('Could not save mode');
    }
    if (_disposed) return;
    this.theme = theme ?? this.theme;
    this.dark = dark ?? this.dark;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class AppearanceScope extends InheritedNotifier<AppearanceController> {
  const AppearanceScope({
    super.key,
    required AppearanceController controller,
    required super.child,
  }) : super(notifier: controller);
  static AppearanceController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppearanceScope>()?.notifier;
}

class AppearanceControls extends StatelessWidget {
  const AppearanceControls({super.key, this.onDark = false});
  final bool onDark;

  Future<void> _save(
    BuildContext context,
    AppearanceController controller, {
    MemberTheme? theme,
    bool? dark,
  }) async {
    try {
      await controller.select(theme: theme, dark: dark);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save appearance. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _choose(
    BuildContext context,
    AppearanceController controller,
  ) async {
    final theme = await showModalBottomSheet<MemberTheme>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Choose your theme',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                for (final theme in MemberTheme.values)
                  ListTile(
                    title: Text(theme.label),
                    subtitle: Text(
                      '${theme.description} · ${switch (theme) {
                        MemberTheme.monochrome => 'Bottom navigation',
                        MemberTheme.gold => 'Side navigation',
                        MemberTheme.roseGold => 'Menu drawer',
                      }}',
                    ),
                    leading: CircleAvatar(
                      backgroundColor: theme.accent,
                      child: const Icon(
                        Icons.palette_outlined,
                        color: Colors.white,
                      ),
                    ),
                    trailing: controller.theme == theme
                        ? const Icon(Icons.check_circle)
                        : null,
                    onTap: () => Navigator.pop(context, theme),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (theme != null && context.mounted) {
      await _save(context, controller, theme: theme);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppearanceScope.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: controller.dark
              ? 'Switch to light mode'
              : 'Switch to dark mode',
          color: onDark ? Colors.white : null,
          icon: Icon(
            controller.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
          ),
          onPressed: () => _save(context, controller, dark: !controller.dark),
        ),
        TextButton.icon(
          style: onDark
              ? TextButton.styleFrom(foregroundColor: Colors.white)
              : null,
          onPressed: () => _choose(context, controller),
          icon: const Icon(Icons.palette_outlined),
          label: const Text('Theme'),
        ),
      ],
    );
  }
}

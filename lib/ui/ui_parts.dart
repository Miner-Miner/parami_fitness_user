import 'package:flutter/material.dart';

import 'app_theme.dart';

class ParamiLogo extends StatelessWidget {
  const ParamiLogo({super.key, this.width = 260});

  static const assetPath = 'assets/branding/parami_fitness_logo.png';

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(width * .05),
        child: ClipRect(
          child: Align(
            alignment: Alignment.center,
            heightFactor: .4,
            child: Image.asset(
              assetPath,
              width: width,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              semanticLabel: 'Parami Fitness',
            ),
          ),
        ),
      ),
    );
  }
}

class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? AppColors.of(context).card,
      borderRadius: BorderRadius.circular(AppColors.of(context).radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: color == AppColors.of(context).navy
                ? LinearGradient(
                    colors: [
                      AppColors.of(context).navy,
                      AppColors.of(context).navyBright,
                    ],
                  )
                : null,
            border: AppColors.of(context).editorial
                ? Border.all(color: AppColors.of(context).line)
                : null,
            borderRadius: BorderRadius.circular(AppColors.of(context).radius),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class LoadingPane extends StatelessWidget {
  const LoadingPane({super.key, this.label = 'Loading your gym details…'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(label, style: TextStyle(color: AppColors.of(context).muted)),
        ],
      ),
    );
  }
}

class EmptyPane extends StatelessWidget {
  const EmptyPane({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.of(context).accentSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 34,
                color: AppColors.of(context).mintDark,
              ),
            ),
            SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.of(context).ink,
              ),
            ),
            SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.of(context).muted,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorPane extends StatelessWidget {
  const ErrorPane({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppColors.of(context).muted,
            ),
            SizedBox(height: 16),
            Text(
              'We couldn’t load this yet',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.of(context).muted,
                height: 1.45,
              ),
            ),
            SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh_rounded),
              label: Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? AppColors.of(context).mintDark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: resolvedColor.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: resolvedColor,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.of(context).ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

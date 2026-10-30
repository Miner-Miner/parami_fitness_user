import 'package:flutter/material.dart';

import '../models/gym_models.dart';
import '../ui/app_theme.dart';
import '../ui/ui_parts.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key, required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(18, 14, 18, 24),
        children: [
          AppSurface(
            padding: EdgeInsets.all(22),
            color: AppColors.of(context).navy,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusPill(
                  label: 'Live member access',
                  color: AppColors.of(context).lime,
                ),
                SizedBox(height: 16),
                Text(
                  'Hello, ${session.name}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Member ID ${session.memberId.isEmpty ? 'not assigned' : session.memberId}',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _QuickCard(
                        icon: Icons.calendar_month_rounded,
                        label: 'Classes',
                        color: AppColors.of(context).mint,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _QuickCard(
                        icon: Icons.qr_code_rounded,
                        label: 'QR Pass',
                        color: AppColors.of(context).lime,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 18),
          SectionLabel(title: 'What you can do'),
          SizedBox(height: 12),
          _ActionCard(
            icon: Icons.sports_gymnastics_rounded,
            title: 'Browse free and paid classes',
            subtitle:
                'See schedules, class details, and book free classes with one tap.',
          ),
          SizedBox(height: 12),
          _ActionCard(
            icon: Icons.card_membership_rounded,
            title: 'Keep an eye on package expiry',
            subtitle:
                'We pop up the nearest expiry reminder whenever you return home.',
          ),
          SizedBox(height: 12),
          _ActionCard(
            icon: Icons.person_outline_rounded,
            title: 'Open your profile tools',
            subtitle:
                'Packages, enrolled classes, and booked free classes are all inside profile.',
          ),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(AppColors.of(context).radius),
        border: Border.all(color: Colors.white.withValues(alpha: .16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 28),
          Text(
            label,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.of(context).accentSoft,
              borderRadius: BorderRadius.circular(AppColors.of(context).radius),
            ),
            child: Icon(icon, color: AppColors.of(context).mintDark),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.of(context).ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.of(context).muted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

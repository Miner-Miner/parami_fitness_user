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
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        children: [
          AppSurface(
            padding: const EdgeInsets.all(22),
            color: AppColors.navy,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StatusPill(
                  label: 'Live member access',
                  color: AppColors.lime,
                ),
                const SizedBox(height: 16),
                Text(
                  'Hello, ${session.name}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Member ID ${session.memberId.isEmpty ? 'not assigned' : session.memberId}',
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _QuickCard(
                        icon: Icons.calendar_month_rounded,
                        label: 'Classes',
                        color: AppColors.mint,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickCard(
                        icon: Icons.qr_code_rounded,
                        label: 'QR Pass',
                        color: AppColors.lime,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionLabel(title: 'What you can do'),
          const SizedBox(height: 12),
          const _ActionCard(
            icon: Icons.sports_gymnastics_rounded,
            title: 'Browse free and paid classes',
            subtitle:
                'See schedules, class details, and book free classes with one tap.',
          ),
          const SizedBox(height: 12),
          const _ActionCard(
            icon: Icons.card_membership_rounded,
            title: 'Keep an eye on package expiry',
            subtitle:
                'We pop up the nearest expiry reminder whenever you return home.',
          ),
          const SizedBox(height: 12),
          const _ActionCard(
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 28),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F7F2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.mintDark),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

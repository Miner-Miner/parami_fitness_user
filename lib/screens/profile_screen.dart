import 'package:flutter/material.dart';

import '../models/gym_models.dart';
import '../services/gym_api.dart';
import '../ui/app_theme.dart';
import '../ui/ui_parts.dart';
import 'member_records_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.api,
    required this.session,
    required this.onLogout,
  });

  final GymApi api;
  final AuthSession session;
  final Future<void> Function() onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<MemberProfile> _future = widget.api.profile(widget.session);

  Future<void> _refresh() async {
    setState(() {
      _future = widget.api.profile(widget.session);
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          children: [
            Text(
              'Profile',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your account, packages, enrolled classes, and booked free classes.',
              style: TextStyle(color: AppColors.muted, height: 1.45),
            ),
            const SizedBox(height: 18),
            FutureBuilder<MemberProfile>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 36),
                    child: LoadingPane(),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 36),
                    child: ErrorPane(
                      message: snapshot.error.toString(),
                      onRetry: _refresh,
                    ),
                  );
                }
                final profile = snapshot.data;
                if (profile == null) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 36),
                    child: EmptyPane(
                      icon: Icons.person_off_rounded,
                      title: 'No profile data',
                      message: 'The server returned an empty profile payload.',
                    ),
                  );
                }
                return AppSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 26,
                            backgroundColor: Color(0xFFE8F7F1),
                            child: Icon(
                              Icons.person_rounded,
                              color: AppColors.mintDark,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.name,
                                  style: const TextStyle(
                                    color: AppColors.ink,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  profile.login,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _ProfileLine(label: 'Member ID', value: profile.memberId),
                      _ProfileLine(label: 'Phone', value: profile.phone),
                      _ProfileLine(label: 'Email', value: profile.email),
                      _ProfileLine(
                        label: 'Address',
                        value: [
                          profile.street,
                          profile.city,
                        ].where((value) => value.isNotEmpty).join(', '),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            const SectionLabel(title: 'Quick access'),
            const SizedBox(height: 12),
            _ProfileAction(
              icon: Icons.card_membership_rounded,
              title: 'Packages',
              subtitle: 'See your membership packages and session balance.',
              onTap: () {
                _openRecords(context, MemberListKind.packages);
              },
            ),
            const SizedBox(height: 12),
            _ProfileAction(
              icon: Icons.event_available_rounded,
              title: 'Enrolled classes',
              subtitle: 'Review the paid class timetable pulled from the API.',
              onTap: () {
                _openRecords(context, MemberListKind.enrolled);
              },
            ),
            const SizedBox(height: 12),
            _ProfileAction(
              icon: Icons.event_note_rounded,
              title: 'Booked free classes',
              subtitle: 'Open your free-class booking history.',
              onTap: () {
                _openRecords(context, MemberListKind.bookedFree);
              },
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () async {
                await widget.onLogout();
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }

  void _openRecords(BuildContext context, MemberListKind kind) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MemberRecordsScreen(
          api: widget.api,
          session: widget.session,
          kind: kind,
        ),
      ),
    );
  }
}

class _ProfileLine extends StatelessWidget {
  const _ProfileLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F7F1),
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
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, height: 1.4),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}

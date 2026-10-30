import 'package:flutter/material.dart';

import '../models/gym_models.dart';
import '../services/gym_api.dart';
import '../ui/app_theme.dart';
import '../ui/ui_parts.dart';
import 'change_password_screen.dart';
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
  late Future<_ProfileData> _future = _loadProfile();

  Future<_ProfileData> _loadProfile() async {
    final results = await Future.wait<Object?>([
      widget.api.profile(widget.session),
      widget.api.loyaltyPoints(widget.session),
    ]);
    return _ProfileData(
      profile: results.first as MemberProfile,
      loyaltyPoints: results.last as LoyaltyPoints?,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadProfile();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(18, 14, 18, 24),
          children: [
            Text(
              'Profile',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.of(context).ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your account, packages, enrolled classes, and booked free classes.',
              style: TextStyle(
                color: AppColors.of(context).muted,
                height: 1.45,
              ),
            ),
            SizedBox(height: 18),
            FutureBuilder<_ProfileData>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Padding(
                    padding: EdgeInsets.only(top: 36),
                    child: LoadingPane(),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: EdgeInsets.only(top: 36),
                    child: ErrorPane(
                      message: snapshot.error.toString(),
                      onRetry: _refresh,
                    ),
                  );
                }
                final profileData = snapshot.data;
                if (profileData == null) {
                  return Padding(
                    padding: EdgeInsets.only(top: 36),
                    child: EmptyPane(
                      icon: Icons.person_off_rounded,
                      title: 'No profile data',
                      message: 'The server returned an empty profile payload.',
                    ),
                  );
                }
                final profile = profileData.profile;
                return AppSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: AppColors.of(context).accentSoft,
                            child: Icon(
                              Icons.person_rounded,
                              color: AppColors.of(context).mintDark,
                            ),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.name,
                                  style: TextStyle(
                                    color: AppColors.of(context).ink,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  profile.login,
                                  style: TextStyle(
                                    color: AppColors.of(context).muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 18),
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
                      _ProfileLine(
                        label: 'Loyalty points',
                        value: profileData.loyaltyPoints?.displayValue ?? '',
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 18),
            SectionLabel(title: 'Quick access'),
            SizedBox(height: 12),
            _ProfileAction(
              icon: Icons.card_membership_rounded,
              title: 'Packages',
              subtitle: 'See your membership packages and session balance.',
              onTap: () {
                _openRecords(context, MemberListKind.packages);
              },
            ),
            SizedBox(height: 12),
            _ProfileAction(
              icon: Icons.event_available_rounded,
              title: 'Enrolled classes',
              subtitle: 'Review the paid class timetable pulled from the API.',
              onTap: () {
                _openRecords(context, MemberListKind.enrolled);
              },
            ),
            SizedBox(height: 12),
            _ProfileAction(
              icon: Icons.event_note_rounded,
              title: 'Booked free classes',
              subtitle: 'Open your free-class booking history.',
              onTap: () {
                _openRecords(context, MemberListKind.bookedFree);
              },
            ),
            SizedBox(height: 12),
            _ProfileAction(
              icon: Icons.lock_reset_rounded,
              title: 'Change password',
              subtitle: 'Update the password used to sign in to your account.',
              onTap: () {
                _openChangePassword();
              },
            ),
            SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () async {
                await widget.onLogout();
              },
              icon: Icon(Icons.logout_rounded),
              label: Text('Logout'),
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

  Future<void> _openChangePassword() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            ChangePasswordScreen(api: widget.api, session: widget.session),
      ),
    );
    if (!mounted || changed != true) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Password changed. Sign in with your new password.'),
      ),
    );
    await widget.onLogout();
  }
}

class _ProfileData {
  const _ProfileData({required this.profile, required this.loyaltyPoints});

  final MemberProfile profile;
  final LoyaltyPoints? loyaltyPoints;
}

class _ProfileLine extends StatelessWidget {
  const _ProfileLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.of(context).muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: TextStyle(
                color: AppColors.of(context).ink,
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
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.of(context).muted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.of(context).muted),
        ],
      ),
    );
  }
}

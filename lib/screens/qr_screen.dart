import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/gym_models.dart';
import '../services/gym_api.dart';
import '../ui/app_theme.dart';
import '../ui/ui_parts.dart';
import 'qr_checkin_screen.dart';

class QrScreen extends StatelessWidget {
  const QrScreen({super.key, required this.api, required this.session});

  final GymApi api;
  final AuthSession session;

  bool get _canScanGymQr {
    if (kIsWeb) {
      return true;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return false;
    }
  }

  Future<void> _openCheckIn(BuildContext context) async {
    final package = await Navigator.of(context).push<PackageRecord>(
      MaterialPageRoute<PackageRecord>(
        builder: (_) => QrCheckInScreen(api: api, session: session),
      ),
    );
    if (!context.mounted || package == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Checked in with ${package.productName}.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
        children: [
          Text(
            'QR Pass',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use your pass for staff scanning, or scan the gym QR to check in yourself.',
            style: TextStyle(color: AppColors.muted, height: 1.45),
          ),
          const SizedBox(height: 18),
          AppSurface(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Text(
                  session.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  session.memberId.isEmpty
                      ? 'Member ID unavailable'
                      : session.memberId,
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: QrImageView(
                    data: session.qrPayload,
                    size: 260,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.navy,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.mintDark,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Show this QR at the gym entrance or staff desk.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F7F1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: AppColors.mintDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Self check-in',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'At the gym, scan the fixed QR poster. We use your current location only to confirm you are on site.',
                  style: TextStyle(color: AppColors.muted, height: 1.45),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _canScanGymQr ? () => _openCheckIn(context) : null,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Scan gym QR to check in'),
                ),
                if (!_canScanGymQr) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'QR scanning is available on Android, iPhone/iPad, macOS, and the web.',
                    style: TextStyle(color: AppColors.muted, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

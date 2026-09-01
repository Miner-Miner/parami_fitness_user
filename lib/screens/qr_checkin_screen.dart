import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/gym_models.dart';
import '../services/gym_api.dart';
import '../ui/app_theme.dart';
import '../ui/formatters.dart';
import '../ui/ui_parts.dart';

class QrCheckInScreen extends StatefulWidget {
  const QrCheckInScreen({super.key, required this.api, required this.session});

  final GymApi api;
  final AuthSession session;

  @override
  State<QrCheckInScreen> createState() => _QrCheckInScreenState();
}

class _QrCheckInScreenState extends State<QrCheckInScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController _scannerController;

  bool _preparing = true;
  bool _locationReady = false;
  bool _submitting = false;
  String? _setupError;
  String? _scanError;
  PackageRecord? _checkedInPackage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController = MobileScannerController(
      facing: CameraFacing.back,
      formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
    _prepareLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_scannerController.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_locationReady || _submitting || _checkedInPackage != null) {
      return;
    }
    if (state == AppLifecycleState.resumed) {
      unawaited(_scannerController.start());
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(_scannerController.stop());
    }
  }

  Future<void> _prepareLocation() async {
    setState(() {
      _preparing = true;
      _locationReady = false;
      _setupError = null;
    });

    try {
      await _ensureLocationAccess();
      if (!mounted) {
        return;
      }
      setState(() {
        _preparing = false;
        _locationReady = true;
      });
    } on _CheckInException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _preparing = false;
        _setupError = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _preparing = false;
        _setupError =
            'We could not prepare your location. Please check your location settings and try again.';
      });
    }
  }

  Future<void> _ensureLocationAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const _CheckInException(
        'Turn on Location Services to check in at the gym.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const _CheckInException(
        'Location permission is needed to confirm that you are at the gym.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const _CheckInException(
        'Location permission is turned off for this app. Enable it in your device settings, then try again.',
      );
    }
  }

  Future<Position> _currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const _CheckInException(
        'Location Services were turned off. Turn them on and scan again.',
      );
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }

  String? _qrValue(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final qrCode = _qrValue(capture);
    if (qrCode == null ||
        !_locationReady ||
        _submitting ||
        _checkedInPackage != null) {
      return;
    }

    setState(() {
      _submitting = true;
      _scanError = null;
    });

    try {
      await _scannerController.stop();
      final position = await _currentPosition();
      final package = await widget.api.checkInWithQr(
        session: widget.session,
        qrCode: qrCode,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _checkedInPackage = package;
      });
    } on TimeoutException {
      _showScanError(
        'We could not get your location in time. Move somewhere with a clearer GPS signal and scan again.',
      );
    } on _CheckInException catch (error) {
      _showScanError(error.message);
    } on ApiException catch (error) {
      _showScanError(error.message);
    } catch (_) {
      _showScanError('We could not complete your check-in. Please try again.');
    }
  }

  void _showScanError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _submitting = false;
      _scanError = message;
    });
  }

  Future<void> _scanAgain() async {
    if (_submitting || _checkedInPackage != null) {
      return;
    }
    setState(() {
      _scanError = null;
    });
    await _scannerController.start();
  }

  @override
  Widget build(BuildContext context) {
    final package = _checkedInPackage;
    if (package != null) {
      return _CheckInSuccessScreen(package: package);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Scan gym QR')),
      body: SafeArea(
        top: false,
        child: _preparing
            ? const LoadingPane(label: 'Preparing secure check-in…')
            : !_locationReady
            ? ErrorPane(
                message: _setupError ?? 'Location access is unavailable.',
                onRetry: _prepareLocation,
              )
            : Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 14, 20, 16),
                    child: Text(
                      'Point your camera at the gym’s fixed self check-in QR poster.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, height: 1.4),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            MobileScanner(
                              controller: _scannerController,
                              onDetect: _onDetect,
                              errorBuilder: (_, error, _) => _CameraError(
                                message:
                                    error.errorDetails?.message ??
                                    'We could not open your camera. Allow camera access and try again.',
                              ),
                            ),
                            const IgnorePointer(child: _ScanFrame()),
                            if (_submitting)
                              const ColoredBox(
                                color: Color(0xA6102331),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                      SizedBox(height: 14),
                                      Text(
                                        'Checking your location and membership…',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (_scanError != null)
                              _ScanFailure(
                                message: _scanError!,
                                onTryAgain: _scanAgain,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 18, 24, 24),
                    child: Text(
                      'Your current location is sent only with this check-in so the gym can confirm you are on site.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, height: 1.4),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _CheckInSuccessScreen extends StatelessWidget {
  const _CheckInSuccessScreen({required this.package});

  final PackageRecord package;

  @override
  Widget build(BuildContext context) {
    final hasSessions = package.totalSessions > 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Check-in complete')),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AppSurface(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE4F6EF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.mintDark,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'You’re checked in',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    package.productName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _ResultLine(
                    label: hasSessions ? 'Sessions remaining' : 'Membership',
                    value: hasSessions
                        ? '${package.remainingSessions}/${package.totalSessions}'
                        : 'Active',
                  ),
                  if (package.expirationDate != null) ...[
                    const SizedBox(height: 12),
                    _ResultLine(
                      label: 'Expires',
                      value: formatDate(package.expirationDate),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(package),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultLine extends StatelessWidget {
  const _ResultLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 230,
        height: 230,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 3),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Color(0x55000000), blurRadius: 16),
          ],
        ),
      ),
    );
  }
}

class _ScanFailure extends StatelessWidget {
  const _ScanFailure({required this.message, required this.onTryAgain});

  final String message;
  final Future<void> Function() onTryAgain;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xC8102331),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Colors.white,
                size: 36,
              ),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, height: 1.4),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => onTryAgain(),
                child: const Text('Scan again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.navy,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                color: Colors.white,
                size: 44,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckInException implements Exception {
  const _CheckInException(this.message);

  final String message;
}

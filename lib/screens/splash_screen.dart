import 'package:flutter/material.dart';

import '../ui/app_theme.dart';
import '../ui/ui_parts.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.of(context).logoCanvas,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ParamiLogo(width: 280),
                SizedBox(height: 26),
                Text(
                  'Your training, membership, and bookings in one place.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, height: 1.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

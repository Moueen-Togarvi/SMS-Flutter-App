import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_rounded, size: 64, color: scheme.primary),
                const SizedBox(height: 20),
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  error ?? 'Preparing offline messaging',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (error == null) ...[
                  const SizedBox(height: 24),
                  const SizedBox(width: 36, height: 36, child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}


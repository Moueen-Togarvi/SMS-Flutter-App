import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/bluetooth_provider.dart';
import '../providers/user_provider.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'splash_screen.dart';

class AppBootstrap extends ConsumerWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(bluetoothProvider);
    final profile = ref.watch(userProvider);

    return profile.when(
      loading: () => const SplashScreen(),
      error: (error, _) => SplashScreen(error: error.toString()),
      data: (profile) => profile == null ? const OnboardingScreen() : const HomeScreen(),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../providers/user_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 56),
            Icon(Icons.bluetooth_connected_rounded, size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'Welcome to ${AppConstants.appName}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              'Choose a name other nearby BlueChat users will see when you connect offline.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  helperText: 'At least 2 characters',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) {
                  if ((value ?? '').trim().length < 2) return 'Enter at least 2 characters.';
                  return null;
                },
                onFieldSubmitted: (_) => _save(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: userState.isLoading ? null : _save,
              icon: userState.isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check_rounded),
              label: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref.read(userProvider.notifier).saveUsername(_controller.text);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}


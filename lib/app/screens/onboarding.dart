import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_state.dart';
import 'home.dart';

/// First launch: privacy choice (GDPR). No age question.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appStateProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Icon(app.config.icon, size: 96, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),
                Text(app.title,
                    textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 24),
                Text(app.t('consent_title'), style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(app.t('consent_body')),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => _done(app, true),
                  child: Text(app.t('accept_all')),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => _done(app, false),
                  child: Text(app.t('essential_only')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _done(AppState app, bool all) async {
    await app.completeOnboarding(acceptAll: all);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }
}

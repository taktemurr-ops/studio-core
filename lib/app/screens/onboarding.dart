import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_state.dart';
import 'home.dart';

/// First launch: neutral age gate + privacy choice (store & GDPR/COPPA).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int? _year;

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appStateProvider);
    final now = DateTime.now().year;
    final years = List.generate(100, (i) => now - i);
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
                Text(app.t('age_question'), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _year,
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: years
                      .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                      .toList(),
                  onChanged: (v) => setState(() => _year = v),
                ),
                const SizedBox(height: 24),
                Text(app.t('consent_title'), style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(app.t('consent_body')),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _year == null ? null : () => _done(app, true),
                  child: Text(app.t('accept_all')),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _year == null ? null : () => _done(app, false),
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
    await app.completeOnboarding(birthYear: _year!, acceptAll: all);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }
}

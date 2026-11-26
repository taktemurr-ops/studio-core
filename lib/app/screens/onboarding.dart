import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_state.dart';
import '../covers.dart';
import '../studio_ui.dart';
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
    final look = StudioLook.of(context);
    return Scaffold(
      backgroundColor: look.base,
      body: StudioBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.all(24),
                shrinkWrap: true,
                children: [
                  Center(
                    child: app.cover != null
                        ? CoverArt(cover: app.cover!, color: app.config.seedColor, size: 112, radius: 26)
                        : StudioIconBadge(app.config.icon, color: look.play, size: 112),
                  ),
                  const SizedBox(height: 14),
                  Text(app.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: look.number,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          shadows: const [Shadow(blurRadius: 8, color: Colors.black54, offset: Offset(0, 2))])),
                  const SizedBox(height: 20),
                  StudioPanel(
                    margin: EdgeInsets.zero,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(app.t('consent_title'),
                          style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text(app.t('consent_body'), style: const TextStyle(color: Color(0xFFD9DCF0), height: 1.35)),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  StudioButton.hot(
                    icon: Icons.check_rounded,
                    label: app.t('accept_all'),
                    onPressed: () => _done(app, true),
                  ),
                  const SizedBox(height: 10),
                  StudioButton(
                    tone: StudioButtonTone.ghost,
                    label: app.t('essential_only'),
                    onPressed: () => _done(app, false),
                  ),
                ],
              ),
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

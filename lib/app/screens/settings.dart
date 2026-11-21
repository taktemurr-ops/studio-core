import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/strings.dart';
import '../adaptive.dart';
import '../app_state.dart';
import '../widgets.dart';
import 'onboarding.dart';
import 'tutorial.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appStateProvider);
    final s = app.save;
    return Scaffold(
      appBar: AppBar(title: Text(app.t('settings'))),
      body: ContentWidth(child: ListView(children: [
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(app.t('language')),
          trailing: DropdownButton<String>(
            value: app.strings.lang,
            onChanged: (v) => app.updateSettings((x) => x.language = v ?? 'en'),
            items: [
              for (final l in Strings.languages)
                DropdownMenuItem(value: l, child: Text(Strings.languageNames[l]!)),
            ],
          ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.volume_up),
          title: Text(app.t('sound')),
          value: s.sound,
          onChanged: (v) => app.updateSettings((x) => x.sound = v),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.music_note),
          title: Text(app.t('music')),
          value: s.music,
          onChanged: (v) => app.updateSettings((x) => x.music = v),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.vibration),
          title: Text(app.t('haptics')),
          value: s.haptics,
          onChanged: (v) => app.updateSettings((x) => x.haptics = v),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.motion_photos_off),
          title: Text(app.t('reduced_motion')),
          value: s.reducedMotion,
          onChanged: (v) => app.updateSettings((x) => x.reducedMotion = v),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.visibility),
          title: Text(app.t('color_blind')),
          value: s.colorBlindMode,
          onChanged: (v) => app.updateSettings((x) => x.colorBlindMode = v),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.back_hand),
          title: Text(app.t('left_handed')),
          value: s.leftHanded,
          onChanged: (v) => app.updateSettings((x) => x.leftHanded = v),
        ),
        ListTile(
          leading: const Icon(Icons.text_fields),
          title: Text(app.t('text_size')),
          subtitle: Slider(
            min: 0.8,
            max: 1.6,
            divisions: 8,
            value: s.textScale.clamp(0.8, 1.6),
            onChanged: (v) => app.updateSettings((x) => x.textScale = v),
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: Text(app.t('how_to_play')),
          onTap: () => showTutorial(context, app),
        ),
        SectionTitle(app.t('privacy')),
        SwitchListTile(
          secondary: const Icon(Icons.analytics),
          title: Text(app.t('analytics_opt')),
          value: s.analyticsConsent,
          onChanged: s.underAge ? null : (v) => app.setAnalyticsConsent(v),
        ),
        ListTile(
          leading: const Icon(Icons.ads_click),
          title: Text(app.t('ad_settings')),
          onTap: () => app.ads.openPrivacyOptions(),
        ),
        ListTile(
          leading: const Icon(Icons.policy),
          title: Text(app.t('privacy_policy')),
          subtitle: Text(app.config.privacyUrl.isEmpty ? 'PRIVACY.md' : app.config.privacyUrl),
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: Text(app.t('delete_data')),
          onTap: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                content: Text(app.t('delete_confirm')),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(c, false), child: Text(app.t('cancel'))),
                  FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(app.t('delete'))),
                ],
              ),
            );
            if (ok == true) {
              await app.deleteAllData();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()), (_) => false);
              }
            }
          },
        ),
        const Divider(),
        AboutListTile(
          icon: const Icon(Icons.info_outline),
          applicationName: app.title,
          applicationVersion: const String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0'),
          child: Text(app.t('about')),
        ),
      ])),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/strings.dart';
import '../adaptive.dart';
import '../app_state.dart';
import '../services/reminders.dart';
import '../studio_ui.dart';
import 'onboarding.dart';
import 'tutorial.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appStateProvider);
    final s = app.save;
    Widget group(List<Widget> rows) => StudioPanel(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Column(children: rows),
        );
    Widget badge(IconData i, Color c) => StudioIconBadge(i, color: c, size: 36);
    return StudioScaffold(
      title: app.t('settings'),
      icon: Icons.settings_rounded,
      body: ContentWidth(
        child: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
          StudioSectionHeader(icon: Icons.tune_rounded, title: app.t('settings')),
          group([
            ListTile(
              leading: badge(Icons.language_rounded, const Color(0xFF2F7BD9)),
              title: Text(app.t('language')),
              // Dil adı alt satırda tam genişlikte (uzun adlar ve büyük yazıda taşmaz).
              subtitle: DropdownButton<String>(
                value: app.strings.lang,
                isExpanded: true,
                underline: const SizedBox(),
                borderRadius: BorderRadius.circular(16),
                onChanged: (v) => app.updateSettings((x) => x.language = v ?? 'en'),
                items: [
                  for (final l in Strings.languages)
                    DropdownMenuItem(
                        value: l, child: Text(Strings.languageNames[l]!, maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
            SwitchListTile(
              secondary: badge(Icons.notifications_active_rounded, const Color(0xFFD9822B)),
              title: Text(app.t('reminder_setting')),
              value: s.reminders,
              onChanged: (v) async {
                final ok = await Reminders.set(v, title: app.t('reminder_title'), body: app.t('reminder_body'));
                app.updateSettings((x) => x.reminders = v && ok);
              },
            ),
            SwitchListTile(
              secondary: badge(Icons.volume_up_rounded, const Color(0xFF2E9E78)),
              title: Text(app.t('sound')),
              value: s.sound,
              onChanged: (v) => app.updateSettings((x) => x.sound = v),
            ),
            SwitchListTile(
              secondary: badge(Icons.music_note_rounded, const Color(0xFF7B4FD6)),
              title: Text(app.t('music')),
              value: s.music,
              onChanged: (v) => app.updateSettings((x) => x.music = v),
            ),
            SwitchListTile(
              secondary: badge(Icons.vibration_rounded, const Color(0xFFC23D7A)),
              title: Text(app.t('haptics')),
              value: s.haptics,
              onChanged: (v) => app.updateSettings((x) => x.haptics = v),
            ),
            SwitchListTile(
              secondary: badge(Icons.motion_photos_off_rounded, const Color(0xFF3C6E8F)),
              title: Text(app.t('reduced_motion')),
              value: s.reducedMotion,
              onChanged: (v) => app.updateSettings((x) => x.reducedMotion = v),
            ),
            SwitchListTile(
              secondary: badge(Icons.visibility_rounded, const Color(0xFF1B998B)),
              title: Text(app.t('color_blind')),
              value: s.colorBlindMode,
              onChanged: (v) => app.updateSettings((x) => x.colorBlindMode = v),
            ),
            ListTile(
              leading: badge(Icons.help_outline_rounded, const Color(0xFF5C6BC0)),
              title: Text(app.t('how_to_play')),
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white70),
              onTap: () => showTutorial(context, app),
            ),
          ]),
          StudioSectionHeader(icon: Icons.shield_rounded, title: app.t('privacy')),
          group([
            SwitchListTile(
              secondary: badge(Icons.analytics_rounded, const Color(0xFF2F7BD9)),
              title: Text(app.t('analytics_opt')),
              value: s.analyticsConsent,
              onChanged: s.underAge ? null : (v) => app.setAnalyticsConsent(v),
            ),
            ListTile(
              leading: badge(Icons.ads_click_rounded, const Color(0xFFD9822B)),
              title: Text(app.t('ad_settings')),
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white70),
              onTap: () => app.ads.openPrivacyOptions(),
            ),
            ListTile(
              leading: badge(Icons.policy_rounded, const Color(0xFF3C6E8F)),
              title: Text(app.t('privacy_policy')),
              trailing: app.config.effectivePrivacyUrl.isEmpty
                  ? null
                  : const Icon(Icons.open_in_new_rounded, color: Colors.white70),
              onTap: app.config.effectivePrivacyUrl.isEmpty
                  ? null
                  : () => launchUrl(Uri.parse(app.config.effectivePrivacyUrl), mode: LaunchMode.externalApplication),
            ),
            ListTile(
              leading: badge(Icons.delete_forever_rounded, StudioLook.bad),
              title: Text(app.t('delete_data'), style: const TextStyle(color: Color(0xFFFF9A9A), fontWeight: FontWeight.w700)),
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    icon: const Icon(Icons.delete_forever_rounded, color: StudioLook.bad, size: 40),
                    content: Text(app.t('delete_confirm')),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: Text(app.t('cancel'))),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: StudioLook.bad, foregroundColor: Colors.white),
                        onPressed: () => Navigator.pop(c, true),
                        child: Text(app.t('delete')),
                      ),
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
          ]),
          const SizedBox(height: 6),
          group([
            AboutListTile(
              icon: badge(Icons.info_outline_rounded, const Color(0xFF5C6BC0)),
              applicationName: app.title,
              applicationVersion: const String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0'),
              child: Text(app.t('about')),
            ),
          ]),
        ]),
      ),
    );
  }
}

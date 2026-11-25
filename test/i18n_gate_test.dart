import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/app/parental_gate.dart';
import 'package:studio_core/core/strings.dart';
import 'package:studio_core/core/strings_world.dart';

void main() {
  test('parental gate texts exist for all 33 languages', () {
    expect(Strings.languages.length, 33);
    for (final l in Strings.languages) {
      final tx = kParentalGateTx[l];
      expect(tx, isNotNull, reason: l);
      expect(tx!.length, 3, reason: l);
      expect(tx.every((x) => x.isNotEmpty), isTrue, reason: l);
    }
  });

  test('world languages use mode_* keys (no mod_* typos)', () {
    for (final e in kWorldStrings.entries) {
      for (final k in e.value.keys) {
        expect(k == 'mods' || k.startsWith('mod_') || k == 'safe_mod', isFalse, reason: '${e.key}: $k');
      }
    }
    expect(Strings('ms').t('mode_campaign'), 'Pengembaraan');
  });
}

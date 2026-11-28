/// Çevrimiçi gerçek zamanlı masanın ekran metinleri (33 dil).
///
/// Türkçe ve İngilizce burada, diğer diller `strings_phrases.dart`
/// tablosunda ([Strings.tx] düzeni).
library;

import 'net_sync.dart';
import 'strings.dart';

/// Bu dosyanın kullandığı İngilizce şablonlar (çeviri denetimi için).
const kNetPhraseKeys = <String>[
  'You',
  'Waiting for players…',
  'Reconnecting…',
  'Host left – you are now the host',
  'Host changed – the game continues',
  '{0} disconnected – AI is playing',
  '{0} (AI)',
  'Leave the match?',
  'The match is still on. If you leave, it counts as a loss and an AI takes your seat.',
  'Leave',
  'Rematch',
  '{0} wants a rematch',
  'Join',
  'This table was opened with another app version. Please update the app.',
  'Syncing the table…',
  'Your turn: {0} s',
];

/// "Sen" etiketi.
String netYou(String lang) => Strings.tx(lang, 'Sen', 'You');

/// Koltuk etiketi: yapay zekâ oynuyorsa "🤖 Ad (YZ)".
String netSeatLabel(String lang, String name, {required bool bot}) =>
    bot ? '🤖 ${Strings.tx(lang, '{0} (YZ)', '{0} (AI)', [name])}' : name;

/// Bağlantı bildiriminin metni ([name]: [NetNote.botPlaying] koltuğunun adı).
/// [NetNote.none] için boş metin.
String netNoteText(String lang, NetNote n, [String name = '']) => switch (n) {
      NetNote.none => '',
      NetNote.waiting => Strings.tx(lang, 'Oyuncular bekleniyor…', 'Waiting for players…'),
      NetNote.reconnecting => Strings.tx(lang, 'Yeniden bağlanıyor…', 'Reconnecting…'),
      NetNote.nowHost =>
        Strings.tx(lang, 'Ev sahibi ayrıldı – oyunu artık sen yürütüyorsun', 'Host left – you are now the host'),
      NetNote.hostChanged => Strings.tx(lang, 'Ev sahibi değişti – oyun sürüyor', 'Host changed – the game continues'),
      NetNote.botPlaying =>
        Strings.tx(lang, '{0} ayrıldı – yerine yapay zekâ oynuyor', '{0} disconnected – AI is playing', [name]),
    };

// ---- Çevrimiçi masa (sıra tabanlı ve gerçek zamanlı ortak) ----------------------------

String netLeaveTitle(String lang) => Strings.tx(lang, 'Maçtan çıkılsın mı?', 'Leave the match?');
String netLeaveBody(String lang) => Strings.tx(lang, 'Maç sürüyor. Çıkarsan yenik sayılırsın ve yerine yapay zekâ oynar.',
    'The match is still on. If you leave, it counts as a loss and an AI takes your seat.');
String netLeaveYes(String lang) => Strings.tx(lang, 'Çık', 'Leave');
String netRematch(String lang) => Strings.tx(lang, 'Rövanş', 'Rematch');
String netRematchOffer(String lang, String name) => Strings.tx(lang, '{0} rövanş istiyor', '{0} wants a rematch', [name]);
String netJoin(String lang) => Strings.tx(lang, 'Katıl', 'Join');
String netUpdateNeeded(String lang) => Strings.tx(lang, 'Bu masa uygulamanın başka bir sürümüyle açılmış. Lütfen uygulamayı güncelleyin.',
    'This table was opened with another app version. Please update the app.');
String netResyncing(String lang) => Strings.tx(lang, 'Masa yeniden eşitleniyor…', 'Syncing the table…');

/// Sıra süresi göstergesi ("Sıra sende: 12 sn").
String netTurnLeft(String lang, int seconds) => Strings.tx(lang, 'Sıra sende: {0} sn', 'Your turn: {0} s', [seconds]);

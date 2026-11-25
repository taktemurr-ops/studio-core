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

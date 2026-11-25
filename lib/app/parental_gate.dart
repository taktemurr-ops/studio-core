import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_state.dart';

/// Parental gate texts in all 33 languages: title, prompt, cancel.
const Map<String, List<String>> kParentalGateTx = {
  'tr': ['Ebeveyn kontrolü', 'Devam etmek için bir yetişkin cevaplasın:', 'Vazgeç'],
  'en': ['Ask a grown-up', 'A grown-up should answer to continue:', 'Cancel'],
  'de': ['Frag einen Erwachsenen', 'Ein Erwachsener sollte antworten, um fortzufahren:', 'Abbrechen'],
  'es': ['Pregunta a un adulto', 'Un adulto debe responder para continuar:', 'Cancelar'],
  'fr': ['Demande à un adulte', 'Un adulte doit répondre pour continuer :', 'Annuler'],
  'ar': ['اسأل شخصًا بالغًا', 'يجب أن يجيب شخص بالغ للمتابعة:', 'إلغاء'],
  'fa': ['از یک بزرگسال بپرس', 'برای ادامه، یک بزرگسال باید پاسخ دهد:', 'لغو'],
  'he': ['שאל מבוגר', 'מבוגר צריך לענות כדי להמשיך:', 'ביטול'],
  'ur': ['کسی بڑے سے پوچھیں', 'جاری رکھنے کے لیے کسی بڑے کو جواب دینا چاہیے:', 'منسوخ'],
  'ru': ['Спроси взрослого', 'Чтобы продолжить, должен ответить взрослый:', 'Отмена'],
  'uk': ['Запитай дорослого', 'Щоб продовжити, має відповісти дорослий:', 'Скасувати'],
  'pl': ['Zapytaj dorosłego', 'Aby kontynuować, odpowiedzieć powinien dorosły:', 'Anuluj'],
  'cs': ['Zeptej se dospělého', 'Pro pokračování by měl odpovědět dospělý:', 'Zrušit'],
  'ro': ['Întreabă un adult', 'Un adult trebuie să răspundă pentru a continua:', 'Anulează'],
  'hu': ['Kérdezz meg egy felnőttet', 'A folytatáshoz egy felnőttnek kell válaszolnia:', 'Mégse'],
  'el': ['Ρώτα έναν ενήλικα', 'Για να συνεχίσεις, πρέπει να απαντήσει ένας ενήλικας:', 'Άκυρο'],
  'it': ['Chiedi a un adulto', 'Un adulto deve rispondere per continuare:', 'Annulla'],
  'pt': ['Pergunte a um adulto', 'Um adulto deve responder para continuar:', 'Cancelar'],
  'nl': ['Vraag het een volwassene', 'Een volwassene moet antwoorden om door te gaan:', 'Annuleren'],
  'sv': ['Fråga en vuxen', 'En vuxen ska svara för att fortsätta:', 'Avbryt'],
  'da': ['Spørg en voksen', 'En voksen skal svare for at fortsætte:', 'Annuller'],
  'nb': ['Spør en voksen', 'En voksen må svare for å fortsette:', 'Avbryt'],
  'fi': ['Kysy aikuiselta', 'Aikuisen tulee vastata jatkaaksesi:', 'Peruuta'],
  'ja': ['大人に聞いてね', '続けるには大人が答えてください：', 'キャンセル'],
  'ko': ['어른에게 물어보세요', '계속하려면 어른이 답해야 해요:', '취소'],
  'zh': ['请问问大人', '需要由大人回答才能继续：', '取消'],
  'hi': ['किसी बड़े से पूछें', 'जारी रखने के लिए किसी बड़े को उत्तर देना चाहिए:', 'रद्द करें'],
  'bn': ['একজন বড়কে জিজ্ঞাসা করো', 'চালিয়ে যেতে একজন প্রাপ্তবয়স্ককে উত্তর দিতে হবে:', 'বাতিল'],
  'id': ['Tanya orang dewasa', 'Orang dewasa harus menjawab untuk melanjutkan:', 'Batal'],
  'ms': ['Tanya orang dewasa', 'Orang dewasa perlu menjawab untuk meneruskan:', 'Batal'],
  'th': ['ถามผู้ใหญ่', 'ผู้ใหญ่ต้องตอบเพื่อดำเนินการต่อ:', 'ยกเลิก'],
  'vi': ['Hỏi người lớn', 'Người lớn cần trả lời để tiếp tục:', 'Hủy'],
  'fil': ['Magtanong sa nakatatanda', 'Dapat sumagot ang isang nakatatanda para magpatuloy:', 'Kanselahin'],
};

/// Simple adult check shown before purchases in kids titles (Google Play
/// Families / Apple Kids category). Other titles pass straight through.
Future<bool> parentalGate(BuildContext context, AppState app) async {
  if (!app.config.kidsMode) return true;
  final r = math.Random();
  final a = 6 + r.nextInt(4), b = 6 + r.nextInt(4);
  final answer = a * b;
  final opts = <int>{answer};
  while (opts.length < 4) {
    opts.add(answer + (r.nextInt(17) - 8));
  }
  final list = opts.toList()..shuffle(r);
  final tx = kParentalGateTx[app.strings.lang] ?? kParentalGateTx['en']!;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(tx[0]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(tx[1]),
        const SizedBox(height: 12),
        Text('$a × $b = ?', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final o in list)
            OutlinedButton(onPressed: () => Navigator.of(ctx).pop(o == answer), child: Text('$o')),
        ]),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(tx[2])),
      ],
    ),
  );
  return ok ?? false;
}

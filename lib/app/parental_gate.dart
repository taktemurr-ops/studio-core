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

/// Adult check shown before purchases, settings and links in kids titles
/// (Google Play Families / Apple Kids category). The product is TYPED on a
/// keypad (a random tap passes ~1/90 instead of 1/4); three wrong answers
/// close the gate. Other titles pass straight through.
Future<bool> parentalGate(BuildContext context, AppState app) async {
  if (!app.config.kidsMode) return true;
  final r = math.Random();
  final a = 6 + r.nextInt(4), b = 6 + r.nextInt(4);
  final tx = kParentalGateTx[app.strings.lang] ?? kParentalGateTx['en']!;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => _GateDialog(a: a, b: b, tx: tx),
  );
  return ok ?? false;
}

class _GateDialog extends StatefulWidget {
  final int a;
  final int b;
  final List<String> tx;
  const _GateDialog({required this.a, required this.b, required this.tx});

  @override
  State<_GateDialog> createState() => _GateDialogState();
}

class _GateDialogState extends State<_GateDialog> {
  String typed = '';
  int fails = 0;
  bool wrong = false;

  void _key(String k) {
    setState(() {
      wrong = false;
      if (k == '<') {
        if (typed.isNotEmpty) typed = typed.substring(0, typed.length - 1);
        return;
      }
      if (typed.length < 3) typed += k;
    });
  }

  void _submit() {
    if (typed.isEmpty) return;
    if (int.tryParse(typed) == widget.a * widget.b) {
      Navigator.of(context).pop(true);
      return;
    }
    fails++;
    if (fails >= 3) {
      Navigator.of(context).pop(false);
      return;
    }
    setState(() {
      typed = '';
      wrong = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget key(String k, {IconData? icon, VoidCallback? onTap}) => Padding(
          padding: const EdgeInsets.all(4),
          child: SizedBox(
            width: 64,
            height: 52,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: onTap ?? () => _key(k),
              child: icon != null ? Icon(icon) : Text(k, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            ),
          ),
        );
    return AlertDialog(
      title: Text(widget.tx[0]),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(widget.tx[1], textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text('${widget.a} × ${widget.b} = ${typed.isEmpty ? '?' : typed}',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: wrong ? const Color(0xFFFF5A5A) : null)),
          ),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (final row in const [
                ['1', '2', '3'],
                ['4', '5', '6'],
                ['7', '8', '9'],
              ])
                Row(mainAxisSize: MainAxisSize.min, children: [for (final k in row) key(k)]),
              Row(mainAxisSize: MainAxisSize.min, children: [
                key('<', icon: Icons.backspace_outlined),
                key('0'),
                key('=', icon: Icons.check_rounded, onTap: _submit),
              ]),
            ]),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(widget.tx[2])),
      ],
    );
  }
}

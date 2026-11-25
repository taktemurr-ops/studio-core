/// İki kişilik gerçek zamanlı masa oyunları (masa tenisi, hava hokeyi,
/// langırt ...) için ortak sözleşme. Simülasyonun alt tarafı (taraf 0)
/// koltuk 0'ın, üst tarafı (taraf 1) koltuk 1'in oyuncusudur. Üst taraftaki
/// oyuncu masayı ters çevrilmiş görür; girdisi de kendi ekranındaki
/// koordinatlarla gelir (simülasyon bunu kendisi çevirir).
library;

import 'arcade.dart';

abstract interface class DuelSim {
  /// Çevrimiçi düello: tek maç oynanır, üst taraf maçı alınca oyun biter
  /// (alt taraf için "kayıp").
  void enableDuel();

  /// Üst taraftaki oyuncunun girdisi (kendi ekran koordinatlarıyla, yani
  /// kendisi alttaymış gibi). null: yerleşik yapay zekâ oynar.
  set rivalInput(ArcadeInput? input);

  /// Ağ üzerinden gönderilecek tam durum (devralma için yeterli olmalı).
  List<double> netState();
  void applyNetState(List<double> s);

  /// İki anlık durum arasında ara kare (yalnızca konumlar yumuşatılır).
  List<double> lerpNet(List<double> a, List<double> b, double f);

  /// Gösterim kopyasını üst taraftaki oyuncunun bakışına çevirir
  /// (taraflar, skorlar ve konumlar yer değiştirir).
  void mirrorView();

  /// Maçı kazanan taraf: 0 alt, 1 üst, -1 sürüyor.
  int get duelWinner;
}

/// [idx] konumlarını doğrusal ara değerle karıştırır; büyük sıçramalarda
/// (sayı sonrası yeniden diziliş) ara kare yapılmaz.
List<double> lerpAt(List<double> a, List<double> b, double f, List<int> idx, {double jump = 220}) {
  if (a.length != b.length) return b;
  final out = List<double>.of(b);
  for (final i in idx) {
    if (i < 0 || i >= a.length) continue;
    final d = b[i] - a[i];
    out[i] = d.abs() > jump ? b[i] : a[i] + d * f;
  }
  return out;
}

/// Üst taraftaki oyuncunun kendi ekran girdisini dünya koordinatlarına
/// çevirir (180° döndürme): x → W-x, y → H-y, yönler ters. Dokunma ve
/// kaydırma (0 = rakibe doğru) olduğu gibi kalır.
ArcadeInput mirrorInput(ArcadeInput i) => ArcadeInput(
      down: i.down,
      x: i.hasPointer ? kWorldW - i.x : -1,
      y: i.hasPointer ? kWorldH - i.y : -1,
      tap: i.tap,
      swipe: i.swipe,
      dirX: -i.dirX,
      dirY: -i.dirY,
    );

/// Kısa "flaş" yazılarının ağ kodu.
int flashCode(String s, List<String> table) {
  final i = table.indexOf(s);
  return i < 0 ? 0 : i;
}

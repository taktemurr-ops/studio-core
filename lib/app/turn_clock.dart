/// Çevrimiçi sıra tabanlı masalarda sıra süresi.
///
/// Popüler çevrimiçi Okey/kart uygulamalarındaki gibi: sıra bu cihazdaki
/// oyuncuya gelince geri sayım başlar; süre dolarsa oyuncu adına yapay zekâ
/// hamlesi yapılır (masa, uygulamayı açık bırakıp ilgilenmeyen bir oyuncu
/// yüzünden sonsuza dek beklemez). Üst üste [autoAfter] kez süresi dolan
/// oyuncunun sonraki sıraları hemen oynanır (masaya dönünce dokunduğu an
/// kontrol geri gelir).
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../core/net_texts.dart';

class TurnClock {
  /// Sıra süresi (saniye). Testler kısaltabilir.
  static int seconds = 30;

  /// Bu kadar üst üste süre dolunca sonraki sıralar beklemeden oynanır.
  static int autoAfter = 3;

  final VoidCallback onChange;

  /// Bu saatin sıra süresi (verilmezse [seconds]); ör. kelime tahtasında daha uzun.
  final int? ownSeconds;
  TurnClock(this.onChange, {int? seconds}) : ownSeconds = seconds;

  /// Geçerli sıra süresi.
  int get total => ownSeconds ?? seconds;

  Timer? _timer;
  int _left = 0;
  int _token = 0;
  int _timeouts = 0;

  /// Kalan saniye (çalışmıyorsa 0).
  int get left => _timer == null ? 0 : _left;
  bool get running => _timer != null;

  /// Üst üste süresi dolan sıra sayısı.
  int get timeouts => _timeouts;

  /// Sıra başladı: [onTimeout] süre dolunca bir kez çağrılır.
  void start(VoidCallback onTimeout) {
    stop();
    final token = ++_token;
    _left = _timeouts >= autoAfter ? 0 : total;
    if (_left <= 0) {
      // Uzun süredir yok: bir sonraki karede oyna.
      _timer = Timer(Duration.zero, () {
        if (token != _token) return;
        _timer = null;
        _timeouts++;
        onTimeout();
      });
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (token != _token) {
        t.cancel();
        return;
      }
      _left--;
      if (_left <= 0) {
        t.cancel();
        _timer = null;
        _timeouts++;
        onTimeout();
      }
      onChange();
    });
    onChange();
  }

  /// Oyuncu kendisi oynadı (ya da sıra bitti).
  void stop({bool byPlayer = false}) {
    _token++;
    _timer?.cancel();
    _timer = null;
    if (byPlayer) _timeouts = 0;
  }

  void dispose() => stop();
}

/// Sıra süresi göstergesi: "Sıra sende: 12 sn" ve azalan çubuk. Son 10
/// saniyede kırmızıya döner.
class TurnTimerChip extends StatelessWidget {
  final TurnClock clock;
  final String lang;
  const TurnTimerChip({super.key, required this.clock, required this.lang});

  @override
  Widget build(BuildContext context) {
    if (!clock.running) return const SizedBox.shrink();
    final left = clock.left;
    final f = clock.total <= 0 ? 0.0 : (left / clock.total).clamp(0.0, 1.0);
    final hot = left <= 10;
    final color = hot ? const Color(0xFFE0533D) : const Color(0xFF2E9E62);
    return Semantics(
      liveRegion: true,
      label: netTurnLeft(lang, left),
      child: Container(
        key: const ValueKey('turn-timer'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.9), width: 1.5),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.timer_rounded, size: 16, color: color),
            const SizedBox(width: 4),
            Text(netTurnLeft(lang, left),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
          ]),
          const SizedBox(height: 4),
          SizedBox(
            width: 110,
            height: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: f,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Televizyon (Android TV / Google TV, Amazon Fire TV) desteği.
///
/// * Algılama: merkezin `MainActivity`'si (tool/store_flavor.py yazar)
///   `studio/device` kanalında `isTv` yanıtlar (UI_MODE_TYPE_TELEVISION,
///   leanback ya da Fire TV özelliği). Kanal yoksa televizyon değildir.
///   `--dart-define=TV_MODE=true` ile zorlanabilir (öykünücü/test).
/// * Uygun merkezler: kart, masa, bilgi, bulmaca, kelime, eşleştirme ve zihin
///   (sıra tabanlı, dokunmaya dayalı oyunlar). Bu merkezler leanback
///   başlatıcısı ve 320x180 afiş bildirir (tool/stores.json `tv_hubs`).
///   Gerçek zamanlı refleks/ritim, kamera ve mikrofon oyunları televizyonda
///   gizlenir ([TvMode.suitable]).
/// * Kumanda: merkez ekranlarında yön tuşları odak gezintisi yapar, orta tuş
///   (DPAD_CENTER/Enter) seçer. Oyun ekranlarında yön tuşları ekranda bir
///   imleç gezdirir; orta tuşa kısa basış dokunma, uzun basış sürükleme
///   başlatır (kartı taşı, ikinci basışta bırak). Menü tuşu imleci her
///   ekranda açar/kapatır. Oyunun kendi klavye desteği (masaüstü) önce gelir.
/// * 10 adım arayüzü: %5 taşma payı (overscan), büyütülmüş yazı ve belirgin
///   odak çerçevesi.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game_api.dart';
import 'hub.dart';

class TvMode {
  TvMode._();

  static const bool forced = bool.fromEnvironment('TV_MODE');
  static const MethodChannel _channel = MethodChannel('studio/device');

  static bool _isTv = forced;

  /// Uygulama televizyonda mı çalışıyor ([init] sonrası).
  static bool get isTv => _isTv;

  @visibleForTesting
  static set debugIsTv(bool v) => _isTv = v;

  /// Televizyona uygun merkezler (tool/stores.json `tv_hubs` ile aynı;
  /// test/tv_test.dart denetler).
  static const Set<String> tvHubs = {
    'merkez-kart-oyunlari',
    'merkez-masa-oyunlari',
    'merkez-bilgi-yarismasi',
    'merkez-bulmaca-oyunlari',
    'merkez-kelime-oyunlari',
    'merkez-eslestirme-oyunlari',
    'merkez-zihin-antrenmani',
  };

  /// Kumandayla oynanamayan oyunları belirten kimlik parçaları (oyun
  /// kimliği `-`/`_` ile bölünür): gerçek zamanlı refleks, ritim, kamera,
  /// mikrofon, serbest çizim.
  static const Set<String> unsuitableParts = {
    'hiz', 'hizli', 'speed', 'refleks', 'reflex', 'tokat', 'slap', 'blitz', 'ritim', 'rhythm', 'tempo',
    'kamera', 'camera', 'mikrofon', 'microphone', 'cizim', 'draw', 'ciz', 'egzersiz',
  };

  static Future<void> init() async {
    if (forced || kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      _isTv = await _channel.invokeMethod<bool>('isTv') ?? false;
    } catch (_) {
      _isTv = false;
    }
  }

  /// Oyun televizyonda (kumandayla) oynanabilir mi?
  static bool suitable(String hubId, String gameId) {
    if (!tvHubs.contains(hubId)) return false;
    final parts = gameId.toLowerCase().split(RegExp(r'[-_]'));
    return !parts.any(unsuitableParts.contains);
  }

  /// Televizyonda uygun olmayan oyunları gizler (telefonda aynen döner).
  static HubConfig filterHub(HubConfig hub, {bool? tv}) {
    if (!(tv ?? isTv)) return hub;
    bool ok(GameConfig g) => suitable(hub.hubId, g.gameId);
    final games = hub.games.where(ok).toList();
    final groups = <HubGroup>[
      for (final g in hub.groups)
        if (g.games.any(ok))
          HubGroup(
              id: g.id,
              title: g.title,
              tagline: g.tagline,
              seedColor: g.seedColor,
              icon: g.icon,
              games: g.games.where(ok).toList()),
    ];
    final ids = {...games.map((g) => g.gameId), ...groups.map((g) => g.id)};
    return HubConfig(
      hubId: hub.hubId,
      title: hub.title,
      tagline: hub.tagline,
      seedColor: hub.seedColor,
      icon: hub.icon,
      games: games,
      groups: groups,
      sections: [
        for (final s in hub.sections)
          if (s.ids.any(ids.contains)) HubSection(title: s.title, ids: s.ids.where(ids.contains).toList()),
      ],
      starters: hub.starters.where(ids.contains).toList(),
      covers: hub.covers,
      defaultCover: hub.defaultCover,
    );
  }

  /// Açık oyun ekranı sayısı: >0 iken imleç kipi etkindir.
  static final ValueNotifier<int> gameDepth = ValueNotifier<int>(0);

  /// Bir oyun ekranını imleç kipinde çalıştırır.
  static Future<T> inGame<T>(Future<T> Function() run) async {
    gameDepth.value++;
    try {
      return await run();
    } finally {
      gameDepth.value--;
    }
  }
}

/// MaterialApp.builder için: televizyonda taşma payı, büyük yazı, belirgin
/// odak ve kumanda imleci. Telefonda/tablette [child] aynen döner.
class TvScope extends StatelessWidget {
  final Widget child;
  final bool? enabled;
  const TvScope({super.key, required this.child, this.enabled});

  /// Yazı büyütme katsayısı (3 m uzaklık).
  static const double textScale = 1.15;

  @override
  Widget build(BuildContext context) {
    if (!(enabled ?? TvMode.isTv)) return child;
    final mq = MediaQuery.of(context);
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return MediaQuery(
      data: mq.copyWith(
        textScaler: TextScaler.linear(mq.textScaler.scale(1) * textScale),
        navigationMode: NavigationMode.directional,
      ),
      child: Theme(
        data: theme.copyWith(
          focusColor: accent.withValues(alpha: 0.45),
          visualDensity: VisualDensity.standard,
        ),
        child: Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
          },
          child: ColoredBox(
            color: theme.scaffoldBackgroundColor,
            child: LayoutBuilder(builder: (context, c) {
              // Android TV / Fire TV: %5 taşma payı (overscan).
              final pad = EdgeInsets.symmetric(horizontal: c.maxWidth * 0.05, vertical: c.maxHeight * 0.05);
              return Padding(
                padding: pad,
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  removeBottom: true,
                  removeLeft: true,
                  removeRight: true,
                  child: TvCursorLayer(child: child),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Kumanda imleci: oyun ekranlarında (ya da Menü tuşuyla) yön tuşları ekranda
/// bir imleç gezdirir, orta tuş dokunur. Dokunma/sürükleme gerçek işaretçi
/// olayları olarak gönderilir; oyun motorlarının değişmesi gerekmez.
class TvCursorLayer extends StatefulWidget {
  final Widget child;
  const TvCursorLayer({super.key, required this.child});

  @override
  State<TvCursorLayer> createState() => TvCursorLayerState();
}

class TvCursorLayerState extends State<TvCursorLayer> {
  final _box = GlobalKey();
  Offset? _pos; // katman içi konum
  bool _manual = false; // Menü tuşuyla açıldı mı
  int _pointer = 900000;
  int? _dragPointer;
  bool _holdStarted = false;
  DateTime? _selectDown;
  int _repeat = 0;

  bool get active => _manual || TvMode.gameDepth.value > 0;

  @visibleForTesting
  Offset? get position => _pos;

  @visibleForTesting
  bool get dragging => _dragPointer != null;

  @override
  void initState() {
    super.initState();
    TvMode.gameDepth.addListener(_changed);
  }

  @override
  void dispose() {
    TvMode.gameDepth.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    if (!active) _cancelDrag();
    setState(() {});
  }

  Size get _size => (_box.currentContext?.findRenderObject() as RenderBox?)?.size ?? Size.zero;

  Offset _global(Offset local) {
    final rb = _box.currentContext?.findRenderObject() as RenderBox?;
    return rb == null ? local : rb.localToGlobal(local);
  }

  int get _viewId => View.of(context).viewId;

  void _send(PointerEvent e) => GestureBinding.instance.handlePointerEvent(e);

  Duration get _now => Duration(microseconds: DateTime.now().microsecondsSinceEpoch);

  void _tap() {
    final p = _global(_pos!);
    final id = ++_pointer;
    final t = _now;
    _send(PointerDownEvent(viewId: _viewId, pointer: id, position: p, timeStamp: t, kind: PointerDeviceKind.touch));
    _send(PointerUpEvent(
        viewId: _viewId, pointer: id, position: p, timeStamp: t + const Duration(milliseconds: 60), kind: PointerDeviceKind.touch));
  }

  void _startDrag() {
    final id = ++_pointer;
    _dragPointer = id;
    _send(PointerDownEvent(viewId: _viewId, pointer: id, position: _global(_pos!), timeStamp: _now, kind: PointerDeviceKind.touch));
  }

  void _endDrag() {
    final id = _dragPointer;
    if (id == null) return;
    _dragPointer = null;
    _send(PointerUpEvent(viewId: _viewId, pointer: id, position: _global(_pos!), timeStamp: _now, kind: PointerDeviceKind.touch));
  }

  void _cancelDrag() {
    final id = _dragPointer;
    if (id == null) return;
    _dragPointer = null;
    _send(PointerCancelEvent(viewId: _viewId, pointer: id, position: _global(_pos ?? Offset.zero), timeStamp: _now, kind: PointerDeviceKind.touch));
  }

  void _move(Offset d, bool repeat) {
    final size = _size;
    _repeat = repeat ? _repeat + 1 : 0;
    // Basılı tutunca hızlanır.
    final step = (size.shortestSide / 24) * (1 + (_repeat / 6).clamp(0, 3));
    final old = _pos ?? size.center(Offset.zero);
    final next = Offset((old.dx + d.dx * step).clamp(0, size.width - 1), (old.dy + d.dy * step).clamp(0, size.height - 1));
    setState(() => _pos = next);
    final id = _dragPointer;
    if (id != null) {
      _send(PointerMoveEvent(
          viewId: _viewId, pointer: id, position: _global(next), delta: next - old, timeStamp: _now, kind: PointerDeviceKind.touch));
    }
  }

  static final _dirs = <LogicalKeyboardKey, Offset>{
    LogicalKeyboardKey.arrowLeft: Offset(-1, 0),
    LogicalKeyboardKey.arrowRight: Offset(1, 0),
    LogicalKeyboardKey.arrowUp: Offset(0, -1),
    LogicalKeyboardKey.arrowDown: Offset(0, 1),
  };

  static bool _isSelect(LogicalKeyboardKey k) =>
      k == LogicalKeyboardKey.select ||
      k == LogicalKeyboardKey.enter ||
      k == LogicalKeyboardKey.numpadEnter ||
      k == LogicalKeyboardKey.gameButtonA;

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.contextMenu) {
      if (e is KeyDownEvent) {
        setState(() => _manual = !_manual);
        if (!active) _cancelDrag();
      }
      return KeyEventResult.handled;
    }
    if (!active) {
      // Merkez ekranları: henüz hiçbir öğe odakta değilse ilk yön tuşu ilk
      // öğeyi odaklar (sonrası Flutter'ın yön gezintisi).
      final f = FocusManager.instance.primaryFocus;
      if (_dirs.containsKey(k) && e is KeyDownEvent && f is FocusScopeNode && f.focusedChild == null) {
        f.nextFocus();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    _pos ??= _size.center(Offset.zero);
    final d = _dirs[k];
    if (d != null) {
      if (e is KeyDownEvent || e is KeyRepeatEvent) _move(d, e is KeyRepeatEvent);
      return KeyEventResult.handled;
    }
    if (_isSelect(k)) {
      if (e is KeyDownEvent) {
        if (_dragPointer != null) {
          _endDrag(); // ikinci basış: bırak
          _selectDown = null;
        } else {
          _selectDown = DateTime.now();
          _holdStarted = false;
        }
      } else if (e is KeyRepeatEvent) {
        final down = _selectDown;
        if (down != null && !_holdStarted && DateTime.now().difference(down) > const Duration(milliseconds: 450)) {
          _holdStarted = true;
          _startDrag(); // uzun basış: tut ve taşı
        }
      } else if (e is KeyUpEvent) {
        if (_selectDown != null && !_holdStarted) _tap();
        _selectDown = null;
      }
      setState(() {});
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Test ve erişilebilirlik için: imleci [local] konumuna koyar.
  @visibleForTesting
  void debugMoveTo(Offset local) => setState(() => _pos = local);

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onKey,
      child: Stack(
        key: _box,
        fit: StackFit.expand,
        children: [
          widget.child,
          if (active && _pos != null)
            Positioned(
              left: _pos!.dx - 14,
              top: _pos!.dy - 14,
              child: IgnorePointer(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (_dragPointer != null ? accent : Colors.white).withValues(alpha: 0.35),
                    border: Border.all(color: _dragPointer != null ? accent : Colors.white, width: 3),
                    boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Kısa yol: televizyonda oyun ekranını imleç kipinde açar.
Future<T> tvGame<T>(Future<T> Function() run) => TvMode.isTv ? TvMode.inGame(run) : run();

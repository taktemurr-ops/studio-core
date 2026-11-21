/// Deterministic, platform-independent random number generator.
///
/// Dart `int` is 64-bit on VM/AOT but a JS double on the web, so all
/// arithmetic here is kept inside 32 bits (with a safe 32x32 multiply) to
/// guarantee that the same seed produces the same level on Android, iOS and
/// Web.
class SeededRandom {
  int _state;

  SeededRandom(int seed) : _state = seed & 0xFFFFFFFF;

  SeededRandom._raw(this._state);

  /// Independent copy continuing the exact same sequence.
  SeededRandom copy() => SeededRandom._raw(_state);

  /// Internal state, for save/resume of deterministic streams.
  int get state => _state;

  factory SeededRandom.fromState(int state) => SeededRandom._raw(state & 0xFFFFFFFF);

  /// 32-bit multiply that never exceeds 2^53 (safe on JS).
  static int imul(int a, int b) {
    a &= 0xFFFFFFFF;
    b &= 0xFFFFFFFF;
    final ah = (a >> 16) & 0xFFFF;
    final al = a & 0xFFFF;
    final bh = (b >> 16) & 0xFFFF;
    final bl = b & 0xFFFF;
    final mid = ((ah * bl + al * bh) & 0xFFFF) << 16;
    return (al * bl + mid) & 0xFFFFFFFF;
  }

  /// mulberry32 step. Returns an unsigned 32-bit integer.
  int nextUint32() {
    _state = (_state + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = _state;
    t = imul(t ^ (t >> 15), t | 1);
    t ^= (t + imul(t ^ (t >> 7), t | 61)) & 0xFFFFFFFF;
    return (t ^ (t >> 14)) & 0xFFFFFFFF;
  }

  /// Uniform integer in [0, max).
  int nextInt(int max) {
    if (max <= 0) throw ArgumentError('max must be > 0');
    return nextUint32() % max;
  }

  /// Uniform integer in [min, max] inclusive.
  int range(int min, int max) => min + nextInt(max - min + 1);

  double nextDouble() => nextUint32() / 4294967296.0;

  bool chance(double p) => nextDouble() < p;

  T pick<T>(List<T> items) => items[nextInt(items.length)];

  void shuffle<T>(List<T> list) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
  }

  /// Picks by integer weights.
  int weighted(List<int> weights) {
    final total = weights.fold<int>(0, (a, b) => a + b);
    var r = nextInt(total);
    for (var i = 0; i < weights.length; i++) {
      r -= weights[i];
      if (r < 0) return i;
    }
    return weights.length - 1;
  }
}

/// Stable 32-bit FNV-1a hash of a string (platform independent).
int stableHash(String input) {
  var h = 0x811C9DC5;
  for (final c in input.codeUnits) {
    h ^= c & 0xFF;
    h = SeededRandom.imul(h, 0x01000193);
    h ^= (c >> 8) & 0xFF;
    h = SeededRandom.imul(h, 0x01000193);
  }
  return h & 0xFFFFFFFF;
}

/// Combines several integers into one seed.
int mixSeed(List<int> parts) {
  var h = 0x9E3779B9;
  for (final p in parts) {
    h ^= p & 0xFFFFFFFF;
    h = SeededRandom.imul(h ^ (h >> 16), 0x85EBCA6B);
    h = SeededRandom.imul(h ^ (h >> 13), 0xC2B2AE35);
    h ^= h >> 16;
  }
  return h & 0xFFFFFFFF;
}

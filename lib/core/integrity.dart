/// Pure-Dart SHA-256 and HMAC-SHA256 (no packages, works on Android, iOS,
/// Web and in tests). Used to sign save data and exported backups so that
/// hand-edited saves (rooted phones, browser localStorage, edited backup
/// strings) are detected and rejected.
///
/// Note: a key shipped inside the app cannot stop a determined attacker; it
/// is a tamper *deterrent* for offline play. Anything with real value
/// (purchases) is verified by the store / server (see docs/PURCHASE_VERIFICATION.md).
class Integrity {
  Integrity._();

  static const List<int> _k = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
  ];

  static int _rotr(int x, int n) => ((x >> n) | (x << (32 - n))) & 0xffffffff;

  /// UTF-8 encoding without dart:convert (keeps core dependency free).
  static List<int> utf8(String s) {
    final out = <int>[];
    final runes = s.runes;
    for (final r in runes) {
      if (r < 0x80) {
        out.add(r);
      } else if (r < 0x800) {
        out..add(0xc0 | (r >> 6))..add(0x80 | (r & 0x3f));
      } else if (r < 0x10000) {
        out..add(0xe0 | (r >> 12))..add(0x80 | ((r >> 6) & 0x3f))..add(0x80 | (r & 0x3f));
      } else {
        out
          ..add(0xf0 | (r >> 18))
          ..add(0x80 | ((r >> 12) & 0x3f))
          ..add(0x80 | ((r >> 6) & 0x3f))
          ..add(0x80 | (r & 0x3f));
      }
    }
    return out;
  }

  static List<int> sha256(List<int> data) {
    final h = <int>[
      0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
    ];
    final bitLen = data.length * 8;
    final msg = List<int>.of(data)..add(0x80);
    while (msg.length % 64 != 56) {
      msg.add(0);
    }
    // 64-bit big-endian length (high word computed without overflowing on web).
    final hi = (bitLen / 4294967296).floor();
    final lo = bitLen & 0xffffffff;
    for (final w in [hi, lo]) {
      msg..add((w >> 24) & 0xff)..add((w >> 16) & 0xff)..add((w >> 8) & 0xff)..add(w & 0xff);
    }
    final w = List<int>.filled(64, 0);
    for (var off = 0; off < msg.length; off += 64) {
      for (var i = 0; i < 16; i++) {
        final j = off + i * 4;
        w[i] = (msg[j] << 24) | (msg[j + 1] << 16) | (msg[j + 2] << 8) | msg[j + 3];
      }
      for (var i = 16; i < 64; i++) {
        final s0 = _rotr(w[i - 15], 7) ^ _rotr(w[i - 15], 18) ^ (w[i - 15] >> 3);
        final s1 = _rotr(w[i - 2], 17) ^ _rotr(w[i - 2], 19) ^ (w[i - 2] >> 10);
        w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & 0xffffffff;
      }
      var a = h[0], b = h[1], c = h[2], d = h[3], e = h[4], f = h[5], g = h[6], hh = h[7];
      for (var i = 0; i < 64; i++) {
        final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
        final ch = (e & f) ^ ((~e & 0xffffffff) & g);
        final t1 = (hh + s1 + ch + _k[i] + w[i]) & 0xffffffff;
        final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
        final maj = (a & b) ^ (a & c) ^ (b & c);
        final t2 = (s0 + maj) & 0xffffffff;
        hh = g;
        g = f;
        f = e;
        e = (d + t1) & 0xffffffff;
        d = c;
        c = b;
        b = a;
        a = (t1 + t2) & 0xffffffff;
      }
      h[0] = (h[0] + a) & 0xffffffff;
      h[1] = (h[1] + b) & 0xffffffff;
      h[2] = (h[2] + c) & 0xffffffff;
      h[3] = (h[3] + d) & 0xffffffff;
      h[4] = (h[4] + e) & 0xffffffff;
      h[5] = (h[5] + f) & 0xffffffff;
      h[6] = (h[6] + g) & 0xffffffff;
      h[7] = (h[7] + hh) & 0xffffffff;
    }
    final out = <int>[];
    for (final v in h) {
      out..add((v >> 24) & 0xff)..add((v >> 16) & 0xff)..add((v >> 8) & 0xff)..add(v & 0xff);
    }
    return out;
  }

  static List<int> hmacSha256(List<int> key, List<int> msg) {
    var k = key.length > 64 ? sha256(key) : List<int>.of(key);
    k = [...k, ...List<int>.filled(64 - k.length, 0)];
    final ipad = [for (final b in k) b ^ 0x36];
    final opad = [for (final b in k) b ^ 0x5c];
    return sha256([...opad, ...sha256([...ipad, ...msg])]);
  }

  static String hex(List<int> bytes) {
    const d = '0123456789abcdef';
    final sb = StringBuffer();
    for (final b in bytes) {
      sb..write(d[b >> 4])..write(d[b & 15]);
    }
    return sb.toString();
  }

  /// Signature of [payload] for one game ([scope] = game id / save prefix).
  static String sign(String scope, String payload) =>
      hex(hmacSha256(utf8('gs100-save-v2|$scope|9f3c1a7e'), utf8(payload)));

  /// Constant-time comparison.
  static bool equals(String a, String b) {
    if (a.length != b.length) return false;
    var r = 0;
    for (var i = 0; i < a.length; i++) {
      r |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return r == 0;
  }
}

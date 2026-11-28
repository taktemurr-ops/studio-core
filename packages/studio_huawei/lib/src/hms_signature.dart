import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// HMS IAP satın alma imzası doğrulaması.
///
/// HUAWEI IAP her siparişin `inAppPurchaseData` JSON metnini uygulamanın
/// IAP ortak anahtarıyla eşleşen özel anahtarla imzalar (varsayılan
/// SHA256WithRSA, istenirse SHA256WithRSA/PSS). Ortak anahtar AppGallery
/// Connect > uygulama > Monetize > In-App Purchases > Settings'teki
/// "Public key"dir (Base64, X.509 SubjectPublicKeyInfo) ve derlemeye
/// `--dart-define=HUAWEI_IAP_PUBLIC_KEY=...` ile verilir (CI gizli değişkeni).
///
/// Anahtar yoksa hiçbir satın alma doğrulanmış sayılmaz: ürün verilmez,
/// tüketilebilir tüketilmez (anahtar eklenince sonraki açılışta teslim edilir).
class HmsSignatureVerifier {
  final RSAPublicKey? _key;

  HmsSignatureVerifier(String base64Key) : _key = _parse(base64Key);

  /// Derleme zamanı anahtarıyla.
  factory HmsSignatureVerifier.fromEnvironment() =>
      HmsSignatureVerifier(const String.fromEnvironment('HUAWEI_IAP_PUBLIC_KEY'));

  bool get configured => _key != null;

  /// [data]: imzalanmış ham JSON metni (ayrıştırılıp yeniden yazılmış değil).
  /// [signature]: Base64 imza. [algorithm]: yanıttaki signatureAlgorithm.
  bool verify(String data, String signature, {String? algorithm}) {
    final key = _key;
    if (key == null || data.isEmpty || signature.isEmpty) return false;
    final Uint8List sig;
    try {
      sig = base64.decode(signature.trim());
    } on FormatException {
      return false;
    }
    final msg = Uint8List.fromList(utf8.encode(data));
    try {
      if ((algorithm ?? '').toUpperCase().contains('PSS')) {
        final s = PSSSigner(RSAEngine(), SHA256Digest(), SHA256Digest());
        // Tuz imzadan okunur; uzunluk SHA-256 çıktısı kadar (32).
        s.init(false, ParametersWithSaltConfiguration(PublicKeyParameter<RSAPublicKey>(key), FortunaRandom(), 32));
        return s.verifySignature(msg, PSSSignature(sig));
      }
      final s = RSASigner(SHA256Digest(), '0609608648016503040201');
      s.init(false, PublicKeyParameter<RSAPublicKey>(key));
      return s.verifySignature(msg, RSASignature(sig));
    } catch (_) {
      return false;
    }
  }

  static RSAPublicKey? _parse(String b64) {
    final clean = b64
        .replaceAll(RegExp(r'-----(BEGIN|END) PUBLIC KEY-----'), '')
        .replaceAll(RegExp(r'\s'), '');
    if (clean.isEmpty) return null;
    try {
      final top = ASN1Parser(base64.decode(clean)).nextObject() as ASN1Sequence;
      // SubjectPublicKeyInfo: { algorithm, BIT STRING { RSAPublicKey } }
      final bits = top.elements![1] as ASN1BitString;
      final inner = ASN1Parser(Uint8List.fromList(bits.stringValues!)).nextObject() as ASN1Sequence;
      final n = (inner.elements![0] as ASN1Integer).integer!;
      final e = (inner.elements![1] as ASN1Integer).integer!;
      return RSAPublicKey(n, e);
    } catch (_) {
      return null;
    }
  }
}

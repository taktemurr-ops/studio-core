import 'package:flutter_test/flutter_test.dart';
import 'package:studio_huawei/studio_huawei.dart';

// Yalnızca bu test için üretilmiş RSA-2048 anahtar çiftinin ORTAK anahtarı
// ve onunla atılmış imzalar (özel anahtar depoda yok).
const _pub = 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApZ2+u8PoB8Yi7rPskMTltxbVIzf/BPuRmMH4JS09oPZ7DUKvIiq8R1pSiKBnQmqw07BMitWn7loq4aoVoyKhhLouoHj9ge81WInI5TSu3l943NOVq6lt9fZxY4FOmymuuk6EO4LeUXYYmVLi41Q9gngsvjoB8hIncsSEsmuoeEnhvLVdXOqNdCya1MoVN+tSPp83lAFf+BNE9zmYWgD1TZd412u0FYkfJuSIvZ6Ofx/1c/4JIQSKXNNqxhB6mYyZwkNLinvL4O221mPZbVj1YwrJUp3nbvIViKbmCU6MOMq4lXN29UjJZZkabCp/Nrhfd4XvsRIjZKRtxfTG/1tQXwIDAQAB';
const _data = "{\"autoRenewing\":false,\"orderId\":\"202611280001\",\"packageName\":\"com.gamestudio100.merkez_verimlilik\",\"applicationId\":1234567,\"kind\":0,\"productId\":\"remove_ads\",\"productName\":\"Reklams\u0131z\",\"purchaseTime\":1764300000000,\"purchaseTimeMillis\":1764300000000,\"purchaseState\":0,\"developerPayload\":\"\",\"purchaseToken\":\"00000173741056a37eef310dff9c6a86fec57efafe318ae478e52d9c4261994d64c8f6fc8ea1abbdx5347.5.3089\",\"consumptionState\":0,\"confirmed\":0,\"currency\":\"TRY\",\"price\":4999,\"country\":\"TR\",\"payOrderId\":\"sandbox20261128\",\"payType\":\"4\"}";
const _sigPkcs1 = 'iyWQcqmrOewQNnzSXIl7CuJ5onA/189Qnk7hD0KinU7GfF48fRI1p6EOK3zLsifZLgajMRKG5Ymu7mJl1/mL2A26Q/byYl8Pmye+Uv9rVqx4FOto+7Up6GyaiH25JiCagO6bw56QRTDV0Xa2gUkA3HqOKy9MyJYAWfNPncqhf1SFjsU++lJEBVVs5wVL/SEke2OPCyhSLEpixUMaGpPPMt6oWYpE/tjCS45kGfT69UbTyF1ZQ4Ulz92D8yO9EJ8S4C0dXjTWUR4kgLbs1+TyAxdmojMbL5w/Xx4DAeLpX2TD8z0y3yX70cZoPZ56Fs9lJiI8OFmTqUWwN3q1BwyQag==';
const _sigPss = 'fQIFdRt9cZ0JiHjU9uKM0IPBlIV+ty9EfuKk21aEeViNKn1WMroLdP73gMzsjNV8SJGNJ0ndxCQenpMO6jvfarSAxlqievpu6IfyOjq3O9f2Z1Kpyp3a0Sp7GoJnAmtyyJYfxyshmMhhY9poJ2b7rmpktdX8lRId6XVLX9KZLe6cSOmWD2as3CXtgCh4PNohjugInv/5NorgybKvGO6lpVho9BVCTJ5IidQ72RlAj6lCjEx4vG6E2mhP7OKoxyM/FsNaMzRpZFGQpWrMvXJt8wg9jT+J2Z7pT6Z+ByhQqLMpa181xumvSY2DaDDaWHHTNbVrkFNwr+rBE20+EY1WCw==';

void main() {
  final v = HmsSignatureVerifier(_pub);

  test('ortak anahtar ayrıştırılır', () {
    expect(v.configured, isTrue);
    expect(HmsSignatureVerifier('').configured, isFalse);
    expect(HmsSignatureVerifier('bozuk!!').configured, isFalse);
    expect(HmsSignatureVerifier('-----BEGIN PUBLIC KEY-----\n$_pub\n-----END PUBLIC KEY-----').configured, isTrue);
  });

  test('SHA256WithRSA ve PSS imzaları doğrulanır', () {
    expect(v.verify(_data, _sigPkcs1), isTrue);
    expect(v.verify(_data, _sigPss, algorithm: 'SHA256WithRSA/PSS'), isTrue);
  });

  test('değiştirilmiş veri, yanlış imza ve anahtarsız derleme reddedilir', () {
    expect(v.verify(_data.replaceFirst('remove_ads', 'premium_pack'), _sigPkcs1), isFalse);
    expect(v.verify(_data, _sigPss), isFalse);
    expect(v.verify(_data, 'AAAA'), isFalse);
    expect(v.verify(_data, ''), isFalse);
    expect(v.verify(_data, 'bu base64 değil'), isFalse);
    expect(HmsSignatureVerifier('').verify(_data, _sigPkcs1), isFalse);
  });

  test('satın alma doğrulaması: imza + ürün + paket + ödeme durumu', () {
    final iap = HmsPurchaseService(verifier: v);
    expect(iap.isVerified(_data, _sigPkcs1), isTrue);
    expect(iap.isVerified(_data, _sigPkcs1, expectedPackage: 'com.gamestudio100.merkez_verimlilik'), isTrue);
    expect(iap.isVerified(_data, _sigPkcs1, expectedPackage: 'com.baska.uygulama'), isFalse);
    expect(iap.isVerified(_data, 'AAAA'), isFalse);
    // Anahtar verilmemiş derleme: hiçbir sipariş doğrulanmış sayılmaz.
    expect(HmsPurchaseService(verifier: HmsSignatureVerifier('')).isVerified(_data, _sigPkcs1), isFalse);
  });

  test('eklenti yanıtından ham imzalı metin alınır', () {
    const raw = '{"returnCode":"0","inAppPurchaseDataList":["{\\"productId\\":\\"remove_ads\\"}"],"inAppPurchaseData":"{\\"a\\":1}"}';
    expect(HmsPurchaseService.rawList(raw, 'inAppPurchaseDataList'), ['{"productId":"remove_ads"}']);
    expect(HmsPurchaseService.rawField(raw, 'inAppPurchaseData'), '{"a":1}');
    expect(HmsPurchaseService.rawField('bozuk', 'x'), '');
  });
}

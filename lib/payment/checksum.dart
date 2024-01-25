import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'dart:math';

import 'package:encrypt/encrypt.dart';

class PaytmChecksum {
  static const String _iv = '@@@@&&&&####\$\$\$\$';

  String encrypt(String input, String key) {
    final encrypter = Encrypter(AES(Key.fromUtf8(key), mode: AESMode.cbc, padding: 'PKCS7'));
    final iv = IV(Uint8List.fromList(utf8.encode(_iv)));
    final encrypted = encrypter.encrypt(input, iv: iv);
    return base64.encode(encrypted.bytes);
  }

  String decrypt(String encrypted, String key) {
    final encrypter = Encrypter(AES(Key.fromUtf8(key), mode: AESMode.cbc, padding: 'PKCS7'));
    final iv = IV(Uint8List.fromList(utf8.encode(_iv)));
    final decrypted = encrypter.decrypt64(encrypted, iv: iv);
    return decrypted;
  }

  String generateSignature(dynamic params, String key) {
    if (params is Map) {
      params = getStringByParams(params);
    }
    return generateSignatureByString(params, key);
  }

  bool verifySignature(dynamic params, String key, String checksum) {
    if (params is Map) {
      if (params.containsKey('CHECKSUMHASH')) {
        params.remove('CHECKSUMHASH');
      }
      params = getStringByParams(params);
    }
    return verifySignatureByString(params, key, checksum);
  }

  String generateSignatureByString(String params, String key) {
    final salt = generateRandomString(4);
    return calculateChecksum(params, key, salt);
  }

  bool verifySignatureByString(String params, String key, String checksum) {
    final paytmHash = decrypt(checksum, key);
    final salt = paytmHash.substring(paytmHash.length - 4);
    return paytmHash == calculateHash(params, salt);
  }

  String generateRandomString(int length) {
    final random = Random.secure();
    final salt = List<int>.generate((length * 3 / 4).ceil(), (i) => random.nextInt(256));
    return base64Url.encode(salt);
  }

  String getStringByParams(Map<dynamic, dynamic> params) {
    params = Map.fromEntries(params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
    return params.values.join('|');
  }

  String calculateHash(String params, String salt) {
    final finalString = '$params|$salt';
    final hashString = sha256.convert(utf8.encode(finalString)).toString();
    return '$hashString$salt';
  }

  String calculateChecksum(String params, String key, String salt) {
    final hashString = calculateHash(params, salt);
    return encrypt(hashString, key);
  }
}


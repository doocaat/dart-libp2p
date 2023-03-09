import 'dart:typed_data';
import 'package:dart_multihash/dart_multihash.dart';
import 'package:dart_multihash/src/multihash/models.dart';
import 'package:bs58/bs58.dart';

extension MultihashBase58 on Multihash {
  static MultihashInfo fromBase58(String from) {
    return Multihash.decode(base58.decode(from));
  }

  String toBase58(Uint8List info) {
    return base58.encode(info);
  }
// ···
}

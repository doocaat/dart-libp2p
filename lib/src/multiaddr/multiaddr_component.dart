

import 'dart:typed_data';

import 'package:dart_libp2p/src/multiaddr/protocol.dart';
import 'package:dart_multihash/src/multihash/varint_utils.dart';
import 'protocol_map.dart';

class MultiaddrComponent {
  Protocol protocol;
  Uint8List value;
  MultiaddrComponent(this.protocol, this.value);
  MultiaddrComponent.fromString(Protocol protocol, String value): this(protocol, protocol.addressToBytes(value));

  Uint8List serialize() {
    var bb = BytesBuilder();
    bb.add(protocol.encoded);

    if(protocol.typeSize == lengthPrefixedVarSize){
      bb.add(encodeVarint(value.length));
    }

    bb.add(value);
    return bb.toBytes();
  }

  @override
  String toString() {
    var component = value.isNotEmpty ? "/${protocol.readAddress(value)}" : "";
    return "/${protocol.name}$component";
  }
}
import 'dart:typed_data';
import 'protocol.dart';
import 'varint_utils.dart';
import 'protocol_type.dart';

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
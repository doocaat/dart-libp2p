import 'dart:typed_data';
import 'package:dart_multihash/src/multihash/varint_utils.dart';
import 'multiaddr_component.dart';
import 'protocol.dart';

class MultiAddress {
  final List<MultiaddrComponent> _components;
  MultiAddress(this._components);
  MultiAddress.fromString(String address) : this(_convertToUint(address));
  MultiAddress.deserialize(Uint8List address) : this(_parseBytes(address));
  

  @override
  String toString() {
    return _components.fold("", (previousValue, element) => "$previousValue$element");
  }

  Uint8List serialize() {
    var bb = BytesBuilder();
    for (var element in _components) {
      bb.add(element.serialize());
    }
    return bb.toBytes();
  }

  static List<MultiaddrComponent> _parseBytes(Uint8List) {
    encodeVarint(value)
  }

  static List<MultiaddrComponent> _convertToUint(String address) {
    while (address.endsWith("/")) {
      address = address.substring(0, address.length -1);
    }
    var parts = address.split("/");

    if (parts[0].isNotEmpty) {
      throw FormatException("MultiAddress must start with a /");
    }
    List<MultiaddrComponent> components = [];

    try {
      for (var i =  1; i < parts.length;) {
        String part = parts[i++];
        Protocol protocol = Protocol.byName(part);
        String component = "";

        if (protocol.typeSize == 0){
          components.add(MultiaddrComponent.fromString(protocol, component));
          continue;
        }

        if (protocol.isTerminal) {
          List<String> list = [];
          List.copyRange<String>(list, i, parts);
          component = list.reduce((value, element) => "$value/$element");
        } else {
          component = parts[i++];
        }

        if (component.isEmpty) {
          throw FormatException("Protocol requires address, but none provided!");
        }

        components.add(MultiaddrComponent.fromString(protocol, component));

        if (protocol.isTerminal) {
          break;
        }
      }
    }
    catch(e) {
      throw FormatException(e.toString());
    }
    return components;
  }
}
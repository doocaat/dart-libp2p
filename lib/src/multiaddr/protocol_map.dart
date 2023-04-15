import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';
import 'protocol.dart';
import 'package:bs58/bs58.dart' as bs;
import 'dart:convert' as convert;
import '../multibase/multibase.dart';
import 'package:fixnum/fixnum.dart';


class ProtocolMap {
  final _nameMap = HashMap<String, Protocol>();
  final _codeMap = HashMap<int, Protocol>();

  ProtocolMap() {
    for (var protocol in ProtocolType.values) {
      _nameMap.addAll({protocol.name: Protocol.fromType(protocol)});
      _codeMap.addAll({protocol.code: Protocol.fromType(protocol)});
    }
  }

  Protocol byName(String name) {
    var protocol = _nameMap[name];
    if (protocol != null) {
     return protocol;
    }

    throw FormatException('No protocol with name: $name');
  }

  Protocol byCode(int code) {
    var protocol = _codeMap[code];
    if (protocol != null) {
      return protocol;
    }

    throw FormatException('No protocol with code: $code');
  }
}

const int lengthPrefixedVarSize = -1;

enum ProtocolType {
  ip4(code: 4, size: 32, name: "ip4", serializer: _Serializer.ipV4, deserializer: _Deserializer.ipV4),
  tcp(code: 6, size: 16, name: "tcp", serializer: _Serializer.uint16, deserializer: _Deserializer.uint16),
  dccp(code: 33, size: 16, name: "dccp", serializer: _Serializer.uint16, deserializer: _Deserializer.uint16),
  ip6(code: 41, size: 128, name: "ip6", serializer: _Serializer.ipV6, deserializer: _Deserializer.ipV6),
  ip6zone(code: 42, size: lengthPrefixedVarSize, name: "ip6zone", serializer: _Serializer.utf8, deserializer: _Deserializer.utf8),
  dns(code: 53, size: lengthPrefixedVarSize, name: "dns", serializer: _Serializer.utf8, deserializer: _Deserializer.utf8),
  dns4(code: 54, size: lengthPrefixedVarSize, name: "dns4", serializer: _Serializer.utf8, deserializer: _Deserializer.utf8),
  dns6(code: 55, size: lengthPrefixedVarSize, name: "dns6", serializer: _Serializer.utf8, deserializer: _Deserializer.utf8),
  dnsaddr(code: 56, size: lengthPrefixedVarSize, name: "dnsaddr", serializer: _Serializer.utf8, deserializer: _Deserializer.utf8),
  sctp(code: 132, size: 16, name: "sctp", serializer: _Serializer.uint16, deserializer: _Deserializer.uint16),
  udp(code: 273, size: 16, name: "udp", serializer: _Serializer.uint16, deserializer: _Deserializer.uint16),
  p2pWebRTC(code: 276, size: 0, name: "p2p-webrtc-direct"),
  utp(code: 301, size: 0, name: "utp"),
  udt(code: 302, size: 0, name: "udt"),
  unix(code: 400, size: lengthPrefixedVarSize, name: "unix", serializer: _Serializer.unix, deserializer: _Deserializer.utf8),
  p2p(code: 421, size: lengthPrefixedVarSize, name: "p2p", serializer: _Serializer.base58, deserializer: _Deserializer.base58),
  ipfs(code: 421, size: lengthPrefixedVarSize, name: "ipfs", serializer: _Serializer.base58, deserializer: _Deserializer.base58),
  http(code: 480, size: 0, name: "http"),
  https(code: 443, size: 0, name: "https"),
  onion3(code: 445, size: 296, name: "onion3", serializer: _Serializer.onion3, deserializer: _Deserializer.onion3),
  tls(code: 448, size: 0, name: "tls"),
  noise(code: 454, size: 0, name: "noise"),
  quic(code: 460, size: 0, name: "quic"),
  quicV1(code: 461, size: 0, name: "quic-v1"),
  webTransport(code: 465, size: 0, name: "webtransport"),
  certHash(code: 466, size: lengthPrefixedVarSize, name: "certhash"),
  ws(code: 477, size: 0, name: "ws"),
  wss(code: 478, size: 0, name: "wss"),
  p2pCircuit(code: 290, size: 0, name: "p2p-circuit");


  const ProtocolType({required this.code, required this.size, required this.name, this.serializer = _Serializer.noImplement, this.deserializer = _Deserializer.noImplement});

  final int code;
  final int size;
  final String name;
  final Uint8List Function(Protocol, String) serializer;
  final String Function(Protocol, Uint8List) deserializer;
}

class _Serializer {

  static Uint8List ipV4(Protocol _, String addr) {
    {
      try {
        var address = InternetAddress(addr);
        if (address.type == InternetAddressType.IPv4) {
          return address.rawAddress;
        }
        throw Exception("Invalid IPv4 address: $addr");
      } catch (e) {
        throw FormatException("Invalid IPv4 address: $addr");
      }
    }
  }

  static Uint8List ipV6(Protocol _, String addr) {
    try {
      var address = InternetAddress(addr);
      if (address.type == InternetAddressType.IPv6) {
        return address.rawAddress;
      }
      throw Exception("Invalid IPv6 address: $addr");
    } catch (e) {
      throw FormatException("Invalid IPv6 address: $addr");
    }
  }

  static Uint8List uint16(Protocol protocol, String addr) {
    int x = int.parse(addr);
    if (x > 65535 || x < 0) {
      throw FormatException(
          "Failed to parse ${protocol.name} address 0 > $addr > 65535");
    }

    var bb = BytesBuilder();
    bb.addByte(x >> 8);
    bb.addByte(x);

    return bb.toBytes();
  }

  static Uint8List base58(Protocol _, String addr) {
    if (!addr.startsWith("Qm") && !addr.startsWith("1")) {
      throw FormatException("Incorrect hash, should star on Qm or 1");
    }
    try {
      var bytes = bs.base58.decode(addr);
      if (bytes.length < 32 || bytes.length > 50) {
        throw FormatException("Invalid hash length: ${bytes.length}");
      }
      return bytes;
    } catch (e) {
      throw FormatException("Incorrect hash: $addr");
    }
  }

  static Uint8List utf8(Protocol _, String addr) {
    return Uint8List.fromList(convert.utf8.encode(addr));
  }

  static Uint8List unix(Protocol _, String addr) {
    if (addr.startsWith("/")) {
      addr = addr.substring(1);
    }
    Uint8List path = Uint8List.fromList(convert.utf8.encode(addr));
    BytesBuilder dout = BytesBuilder();
    Uint8List length =
    Uint8List((((32 - Int32(path.length).numberOfLeadingZeros() + 6) / 7).floor()));
    Protocol.putUvarint(length, path.length);
    dout.add(length);
    dout.add(path);
    return Uint8List.fromList(convert.utf8.encode(addr));
  }

  static Uint8List onion3(Protocol protocol, String addr) {
    List<String> split = addr.split(":");
    if (split.length != 2) {
      throw FormatException("Onion3 address needs a port: $addr");
    }

    // onion3 address without the ".onion" substring
    if (split[0].length != 56) {
      throw FormatException(
          "failed to parse ${protocol.name} addr: $addr not a Tor onion3 address.");
    }

    Uint8List onionHostBytes = multibaseDecode("b${split[0]}");
    if (onionHostBytes.length != 35) {
      throw FormatException("Invalid onion3 address host: ${split[0]}");
    }

    int port = int.parse(split[1]);
    if (port > 65535) {
      throw FormatException("Port is > 65535: $port");
    }

    if (port < 1) {
      throw FormatException("Port is < 1: $port");
    }

    var bb = BytesBuilder()
      ..add(onionHostBytes)
      ..addByte(port >> 8)
      ..addByte(port);
    return bb.toBytes();
  }

  static Uint8List noImplement(Protocol protocol, String _) {
    throw Exception("No value serializer for protocol $protocol");
  }
}

class _Deserializer {
  static String ipV4(Protocol _, Uint8List addr) {
    try {
      return InternetAddress.fromRawAddress(addr).address;
    } catch (e) {
      throw FormatException("Invalid IPv4 address: $addr");
    }
  }

  static String ipV6(Protocol _, Uint8List addr) {
    try {
      return InternetAddress.fromRawAddress(addr).address;
    } catch (e) {
      throw FormatException("Invalid IPv6 address: $addr");
    }
  }

  static String uint16(Protocol _, Uint8List addr) {
    return ((addr[0] << 8) + addr[1]).toString();
  }

  static String base58(Protocol _, Uint8List addr) {
    return bs.base58.encode(addr);
  }

  static String utf8(Protocol _, Uint8List addr) {
    return convert.utf8.decode(addr);
  }

  static String onion3(Protocol _, Uint8List addr) {
    var host = Uint8List.fromList(addr.getRange(0, 35).toList());
    var portBytes = Uint8List.fromList(addr.getRange(35, addr.length).toList());
    var port = ((portBytes[0] << 8) + portBytes[1]);
    return "${multibaseEncode(Multibase.base32, host).substring(1)}:$port";
  }

  static String noImplement(Protocol protocol, Uint8List _) {
    throw Exception("No value deserializer for protocol $protocol");
  }
}

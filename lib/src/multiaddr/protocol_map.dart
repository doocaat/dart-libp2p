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
  IP4(4, 32, "ip4", _Serializer.ipV4, _Deserializer.ipV4),
  TCP(6, 16, "tcp", _Serializer.uint16, _Deserializer.uint16),
  DCCP(33, 16, "dccp", _Serializer.uint16, _Deserializer.uint16),
  IP6(41, 128, "ip6", _Serializer.ipV6, _Deserializer.ipV6),
  IP6ZONE(42, lengthPrefixedVarSize, "ip6zone", _Serializer.utf8, _Deserializer.utf8),
  DNS(53, lengthPrefixedVarSize, "dns", _Serializer.utf8, _Deserializer.utf8),
  DNS4(54, lengthPrefixedVarSize, "dns4", _Serializer.utf8, _Deserializer.utf8),
  DNS6(55, lengthPrefixedVarSize, "dns6", _Serializer.utf8, _Deserializer.utf8),
  DNSADDR(56, lengthPrefixedVarSize, "dnsaddr", _Serializer.utf8, _Deserializer.utf8),
  SCTP(132, 16, "sctp", _Serializer.uint16, _Deserializer.uint16),
  UDP(273, 16, "udp", _Serializer.uint16, _Deserializer.uint16),
  P2PWEBRTC(276, 0, "p2p-webrtc-direct", _Serializer.noImplement, _Deserializer.noImplement),
  UTP(301, 0, "utp", _Serializer.noImplement, _Deserializer.noImplement),
  UDT(302, 0, "udt", _Serializer.noImplement, _Deserializer.noImplement),
  UNIX(400, lengthPrefixedVarSize, "unix", _Serializer.unix, _Deserializer.utf8),
  P2P(421, lengthPrefixedVarSize, "p2p", _Serializer.base58, _Deserializer.base58),
  IPFS(421, lengthPrefixedVarSize, "ipfs", _Serializer.base58, _Deserializer.base58),
  HTTPS(443, 0, "https", _Serializer.noImplement, _Deserializer.noImplement),
  ONION3(445, 296, "onion3", _Serializer.onion3, _Deserializer.onion3),
  TLS(448, 0, "tls", _Serializer.noImplement, _Deserializer.noImplement),
  NOISE(454, 0, "noise", _Serializer.noImplement, _Deserializer.noImplement),
  QUIC(460, 0, "quic", _Serializer.noImplement, _Deserializer.noImplement),
  QUIC_V1(461, 0, "quic-v1", _Serializer.noImplement, _Deserializer.noImplement),
  WEBTRANSPORT(465, 0, "webtransport", _Serializer.noImplement, _Deserializer.noImplement),
  CERTHASH(466, lengthPrefixedVarSize, "certhash", _Serializer.noImplement, _Deserializer.noImplement),
  WS(477, 0, "ws", _Serializer.noImplement, _Deserializer.noImplement),
  WSS(478, 0, "wss", _Serializer.noImplement, _Deserializer.noImplement),
  P2PCIRCUIT(290, 0, "p2p-circuit", _Serializer.noImplement, _Deserializer.noImplement),
  HTTP(480, 0, "http", _Serializer.noImplement, _Deserializer.noImplement);

  const ProtocolType(this.code, this.size, this.name, this.serializer, this.deserializer);

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

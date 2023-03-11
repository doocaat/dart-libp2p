import 'dart:collection';
import 'dart:typed_data';
import 'protocol.dart';

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
  IP4(4, 32, "ip4"),
  TCP(6, 16, "tcp"),
  DCCP(33, 16, "dccp"),
  IP6(41, 128, "ip6"),
  IP6ZONE(42, lengthPrefixedVarSize, "ip6zone"),
  IPCIDR(43, 8, "ipcidr"),
  DNS(53, lengthPrefixedVarSize, "dns"),
  DNS4(54, lengthPrefixedVarSize, "dns4"),
  DNS6(55, lengthPrefixedVarSize, "dns6"),
  DNSADDR(56, lengthPrefixedVarSize, "dnsaddr"),
  SCTP(132, 16, "sctp"),
  UDP(273, 16, "udp"),
  P2PWEBRTC(276, 0, "p2p-webrtc-direct"),
  UTP(301, 0, "utp"),
  UDT(302, 0, "udt"),
  UNIX(400, lengthPrefixedVarSize, "unix"),
  P2P(421, lengthPrefixedVarSize, "p2p"),
  IPFS(421, lengthPrefixedVarSize, "ipfs"),
  HTTPS(443, 0, "https"),
  ONION3(445, 296, "onion3"),
  TLS(448, 0, "tls"),
  NOISE(454, 0, "noise"),
  QUIC(460, 0, "quic"),
  QUIC_V1(461, 0, "quic-v1"),
  WEBTRANSPORT(465, 0, "webtransport"),
  CERTHASH(466, lengthPrefixedVarSize, "certhash"),
  WS(477, 0, "ws"),
  WSS(478, 0, "wss"),
  P2PCIRCUIT(290, 0, "p2p-circuit"),
  HTTP(480, 0, "http");

  const ProtocolType(this.code, this.size, this.name);

  final int code;
  final int size;
  final String name;
}

Uint8List _int32bytes(int value) =>
    Uint8List(4)..buffer.asInt32List()[0] = value;

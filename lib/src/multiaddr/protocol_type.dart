enum ProtocolType {
  IP4(4, 32, "ip4"),
  TCP(6, 16, "tcp"),
  DCCP(33, 16, "dccp"),
  IP6(41, 128, "ip6"),
  IP6ZONE(42, _lengthPrefixedVarSize, "ip6zone"),
  IPCIDR(43, 8, "ipcidr"),
  DNS(53, _lengthPrefixedVarSize, "dns"),
  DNS4(54, _lengthPrefixedVarSize, "dns4"),
  DNS6(55, _lengthPrefixedVarSize, "dns6"),
  DNSADDR(56, _lengthPrefixedVarSize, "dnsaddr"),
  SCTP(132, 16, "sctp"),
  UDP(273, 16, "udp"),
  P2PWEBRTC(276, 0, "p2p-webrtc-direct"),
  UTP(301, 0, "utp"),
  UDT(302, 0, "udt"),
  UNIX(400, _lengthPrefixedVarSize, "unix"),
  P2P(421, _lengthPrefixedVarSize, "p2p"),
  IPFS(421, _lengthPrefixedVarSize, "ipfs"),
  HTTPS(443, 0, "https"),
  ONION(444, 80, "onion"),
  ONION3(445, 296, "onion3"),
  GARLIC64(446, _lengthPrefixedVarSize, "garlic64"),
  GARLIC32(447, _lengthPrefixedVarSize, "garlic32"),
  TLS(448, 0, "tls"),
  NOISE(454, 0, "noise"),
  QUIC(460, 0, "quic"),
  WEBTRANSPORT(465, 0, "webtransport"),
  CERTHASH(466, _lengthPrefixedVarSize, "certhash"),
  WS(477, 0, "ws"),
  WSS(478, 0, "wss"),
  P2PCIRCUIT(290, 0, "p2p-circuit"),
  HTTP(480, 0, "http");

  const ProtocolType(this.code, this.size, this.name);

  final int code;
  final int size;
  final String name;
}

const int _lengthPrefixedVarSize = -1;
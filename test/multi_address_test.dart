import 'dart:io';
import 'package:dart_libp2p/src/multiaddr/multi_address.dart';
import 'package:test/test.dart';

void main() {
  final invalidAddressList = [
    "/ip4",
    "/ip4/::1",
    "/ip4/0:0:0:0:0:0:0:1",
    "/ip4/consensys.net",
    "/ip4/123.2.3",
    "/ip4/123.2.3.5.6",
    "/ip4/123.2.3.256",
    "/ip4/fdpsofodsajfdoisa",
    "/ip6",
    "/ip6/consensys.net",
    "/ip6/127.0.0.1",
    "/ip6/0:0:0:0:0:0:0:1::",
    "/ip6/0:0:0:0:0:0:0:1:2",
    "/ip6/0:0:0:0:0:0:1",
    "/ip6zone",
    "/ip6zone/",
    "/ip6zone//ip6/fe80::1",
    "/udp",
    "/tcp",
    "/sctp",
    "/udp/65536",
    "/udp/-2",
    "/udp/abc",
    "/udp/",
    "/udp//",
    "/udp/ /",
    "/udp /123",
    "/udp/123 ",
    "/udp/123\n",
    "/udp/\n123",
    "/udp\n/123",
    "/\nudp/123",
    "\n/udp/123",
    "/ udp/123",
    "udp/123",
    "/tcp/65536",
    "/quic/65536",
    "/onion/9imaq4ygg2iegci7:80",
    "/onion/aaimaq4ygg2iegci7:80",
    "/onion/timaq4ygg2iegci7:0",
    "/onion/timaq4ygg2iegci7:-1",
    "/onion/timaq4ygg2iegci7",
    "/onion/timaq4ygg2iegci@:666",
    "/udp/1234/sctp",
    "/udp/1234/udt/1234",
    "/udp/1234/utp/1234",
    "/ip4/127.0.0.1/udp/jfodsajfidosajfoidsa",
    "/ip4/127.0.0.1/udp",
    "/ip4/127.0.0.1/tcp/jfodsajfidosajfoidsa",
    "/ip4/127.0.0.1/tcp",
    "/ip4/127.0.0.1/quic/1234",
    "/ip4/127.0.0.1/ipfs",
    "/ip4/127.0.0.1/ipfs/tcp",
    "/ip4/127.0.0.1/p2p",
    "/ip4/127.0.0.1/p2p/tcp",
    "/unix",
    "/ip4/1.2.3.4/tcp/80/unix",
    // too short PeerId
    "/p2p/QmcgpsyWgH8Y8ajJz1Cu72",
    // too long PeerId
    "/p2p/QmcgpsyWgH8Y8ajJz1Cu72KnS5uo2Aa2LpzU7kinSupNKC55555555555555555555555555555555555",

    "/onion3/9ww6ybal4bd7szmgncyruucpgfkqahzddi37ktceo3ah7ngmcopnpyyd:80",
    "/onion3/vww6ybal4bd7szmgncyruucpgfkqahzddi37ktceo3ah7ngmcopnpyyd7:80",
    "/onion3/vww6ybal4bd7szmgncyruucpgfkqahzddi37ktceo3ah7ngmcopnpyyd:0",
    "/onion3/vww6ybal4bd7szmgncyruucpgfkqahzddi37ktceo3ah7ngmcopnpyyd:-1",
    "/onion3/vww6ybal4bd7szmgncyruucpgfkqahzddi37ktceo3ah7ngmcopnpyyd",
    "/onion3/vww6ybal4bd7szmgncyruucpgfkqahzddi37ktceo3ah7ngmcopnpyy@:666",
  ];
  final validAddressList = [
    "/ip4/1.2.3.4",
    "/ip4/0.0.0.0",
    "/ip6/::1",
    "/ip6/2601:9:4f81:9700:803e:ca65:66e8:c21",
    "/ip6/2601:9:4f81:9700:803e:ca65:66e8:c21/udp/1234/quic",
    "/ip6zone/x/ip6/fe80::1",
   "/ip6zone/x%y/ip6/fe80::1",
    "/ip6zone/x%y/ip6/::",
    "/ip6zone/x/ip6/fe80::1/udp/1234/quic",
    "/ip6/::1/udp/4001/quic-v1",
    "/dnsaddr/bootstrap.libp2p.io/ipfs/QmbLHAnMoJPWSCR5Zhtx6BHJX9KiKNN6tpvbUcqanj75Nb",
    "/ip4/127.0.0.1/udp/4001/quic-v1/webtransport",
    "/onion3/vww6ybal4bd7szmgncyruucpgfkqahzddi37ktceo3ah7ngmcopnpyyd:1234",
    "/onion3/vww6ybal4bd7szmgncyruucpgfkqahzddi37ktceo3ah7ngmcopnpyyd:80/http",
    "/udp/0",
    "/tcp/0",
    "/sctp/0",
    "/udp/1234",
    "/tcp/1234",
    "/sctp/1234",
    "/udp/65535",
    "/tcp/65535",
    "/ipfs/QmcgpsyWgH8Y8ajJz1Cu72KnS5uo2Aa2LpzU7kinSupNKC",
    "/p2p/QmcgpsyWgH8Y8ajJz1Cu72KnS5uo2Aa2LpzU7kinSupNKC",
    "/p2p/12D3KooWCryG7Mon9orvQxcS1rYZjotPgpwoJNHHKcLLfE4Hf5mV",
    "/udp/1234/sctp/1234",
    "/udp/1234/udt",
    "/udp/1234/utp",
    "/tcp/1234/http",
    "/tcp/1234/tls/http",
    "/tcp/1234/https",
    "/ipfs/QmcgpsyWgH8Y8ajJz1Cu72KnS5uo2Aa2LpzU7kinSupNKC/tcp/1234",
    "/ipfs/16Uiu2HAkuqGKz8D6khfrnJnDrN5VxWWCoLU8Aq4eCFJuyXmfakB5/tcp/1234",
    "/p2p/QmcgpsyWgH8Y8ajJz1Cu72KnS5uo2Aa2LpzU7kinSupNKC/tcp/1234",
    "/p2p/16Uiu2HAkuqGKz8D6khfrnJnDrN5VxWWCoLU8Aq4eCFJuyXmfakB5/tcp/1234",
    "/ip4/127.0.0.1/udp/1234",
    "/ip4/127.0.0.1/udp/0",
    "/ip4/127.0.0.1/tcp/1234",
    "/ip4/127.0.0.1/udp/1234/quic",
    "/ip4/127.0.0.1/udp/1234/quic/webtransport",
    "/ip4/127.0.0.1/ipfs/QmcgpsyWgH8Y8ajJz1Cu72KnS5uo2Aa2LpzU7kinSupNKC",
    "/ip4/127.0.0.1/ipfs/QmcgpsyWgH8Y8ajJz1Cu72KnS5uo2Aa2LpzU7kinSupNKC/tcp/1234",
    "/ip4/127.0.0.1/p2p/QmcgpsyWgH8Y8ajJz1Cu72KnS5uo2Aa2LpzU7kinSupNKC",
    "/ip4/127.0.0.1/p2p/QmcgpsyWgH8Y8ajJz1Cu72KnS5uo2Aa2LpzU7kinSupNKC/tcp/1234",
    "/unix/a/b/c/d/e",
    "/unix/stdio",
    "/ip4/1.2.3.4/tcp/80/unix/a/b/c/d/e/f",
    "/ip4/127.0.0.1/ipfs/QmcgpsyWgH8Y8ajJz1Cu72KnS5uo2Aa2LpzU7kinSupNKC/tcp/1234/unix/stdio",
    "/ip4/127.0.0.1/p2p/QmcgpsyWgH8Y8ajJz1Cu72KnS5uo2Aa2LpzU7kinSupNKC/tcp/1234/unix/stdio",
    "/ip4/127.0.0.1/tcp/9090/http/p2p-webrtc-direct",
    "/ip4/127.0.0.1/tcp/127/ws",
    "/ip4/127.0.0.1/tcp/127/ws",
    "/ip4/127.0.0.1/tcp/127/tls",
    "/ip4/127.0.0.1/tcp/127/tls/ws",
    "/ip4/127.0.0.1/tcp/127/noise",
    "/ip4/127.0.0.1/tcp/127/wss",
    "/ip6/0:0:0:0:0:0:0:1",// error
    "/ip6/1::",
    "/ip6/1::2323:abcd",
    "/ip6/::",
    "/ip6/::ffff",
    "/ip6zone/x/ip6/fe80:0:0:0:0:0:0:1",
    "/ip6zone/x%y/ip6/fe80:0:0:0:0:0:0:1",
    "/ip6zone/x%y/ip6/0:0:0:0:0:0:0:0",
    "/ip6zone/x/ip6/fe80:0:0:0:0:0:0:1/udp/1234/quic",
    "/ipfs/QmcgpsyWgH8Y8ajJz1Cu72KnS5uo2Aa2LpzU7kinSupNKC/tcp/1234",
    "/ip4/127.0.0.1/tcp/40001/p2p/16Uiu2HAkuqGKz8D6khfrnJnDrN5VxWWCoLU8Aq4eCFJuyXmfakB5"
  ];

  // for (String address in invalidAddressList) {
  //   test("Invalid address $address", () {
  //     expect(() => MultiAddress.fromString(address), throwsA(isA<FormatException>()));
  //   });
  // }

  for (String address in validAddressList) {
    test("Valid address $address", () {
      var multiaddr = MultiAddress.fromString(address);
      var multiaddr1 = MultiAddress.fromBytes(multiaddr.toBytes());
      expect(toCanonical(address), multiaddr1.toString());

    });
  }
}

String toCanonical(String multiaddr) {
  if(multiaddr.endsWith("/")) {
    multiaddr = multiaddr.substring(0, multiaddr.length -1);
  }
  multiaddr = multiaddr.replaceAll("/p2p/", "/ipfs/");

  var parts = multiaddr.split("/");

  for (var i =  1; i < parts.length;) {
    String part = parts[i++];
    if(part == 'ip6') {
      var ipv6 = parts[i++];
      var inet =  InternetAddress(ipv6);
      parts[i - 1] = InternetAddress.fromRawAddress(inet.rawAddress).address;
    }

  }

  return parts.join("/");
}
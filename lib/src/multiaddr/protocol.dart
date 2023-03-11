import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dart_multihash/src/multihash/varint_utils.dart';
import 'package:fixnum/fixnum.dart';
import '../multibase/multibase.dart';
import 'protocol_map.dart';
import 'package:bs58/bs58.dart' as bs;
import 'package:buffer/buffer.dart';

class Protocol {
  static final map = ProtocolMap();

  final ProtocolType _type;
  final Uint8List encoded;

  Protocol(this._type, this.encoded);

  Protocol.fromType(type) : this(type, encode(type.code));

  int size() {
    return _type.size;
  }

  static Uint8List encode(int c) {
    ByteDataWriter writer = ByteDataWriter(bufferLength: 4);
    writer.write(encodeVarint(c));

    return writer.toBytes();
  }

  static int putUvarint(Uint8List buf, int x) {
      int i = 0;
      while (x >= 0x80) {
        buf[i] = (x | 0x80);
        x >>= 7;
        i = i+1;
      }
      buf[i] = x;
      return i + 1;
      return decodeVarint(buf, x).numBytesRead;
  }

  static Protocol byName(String name) {
    return map.byName(name);
  }

  static Protocol byCode(int code) {
    return map.byCode(code);
  }

  int get code {
    return _type.code;
  }

  int get typeSize {
    return _type.size;
  }

  bool get isTerminal {
    return _type == ProtocolType.UNIX;
  }

  String get name {
    return _type.name;
  }

  Uint8List addressToBytes(String addr) {
    if(addr.isEmpty){
      return Uint8List(0);
    }
    try {
      switch (_type) {
        case ProtocolType.IP4:
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

        case ProtocolType.IP6:
          try {
            var address = InternetAddress(addr);
            if (address.type == InternetAddressType.IPv6) {
              return address.rawAddress;
            }
            throw Exception("Invalid IPv6 address: $addr");
          } catch (e) {
            throw FormatException("Invalid IPv6 address: $addr");
          }
        case ProtocolType.IP6ZONE:
          if (addr.isEmpty) {
            throw FormatException("Empty IPv6 zone!");
          }

          if (addr.contains("/")) {
            throw FormatException("IPv6 zone ID contains '/'");
          }

          return Uint8List.fromList(utf8.encode(addr));
        case ProtocolType.TCP:
        case ProtocolType.UDP:
        case ProtocolType.DCCP:
        case ProtocolType.SCTP:
          {
            int x = int.parse(addr);
            if (x > 65535 || x < 0) {
              throw FormatException(
                  "Failed to parse ${_type.name} address 0 > $addr > 65535");
            }

            var bb = BytesBuilder();
            bb.addByte(x >> 8);
            bb.addByte(x);
            return bb.toBytes();
          }
        case ProtocolType.P2P:
        case ProtocolType.IPFS:
          {
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
        case ProtocolType.ONION3:
          {
            List<String> split = addr.split(":");
            if (split.length != 2) {
              throw FormatException("Onion3 address needs a port: $addr");
            }

            // onion3 address without the ".onion" substring
            if (split[0].length != 56) {
              throw FormatException(
                  "failed to parse $name addr: $addr not a Tor onion3 address.");
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

            BytesBuilder dout = BytesBuilder();
            dout.add(onionHostBytes);
            dout.addByte(port >> 8);
            dout.addByte(port);
            return dout.toBytes();
          }
        case ProtocolType.UNIX:
          {
            if (addr.startsWith("/")) {
              addr = addr.substring(1);
            }
            Uint8List path = Uint8List.fromList(utf8.encode(addr));
            BytesBuilder dout = BytesBuilder();
            Uint8List length =
                Uint8List((((32 - Int32(path.length).numberOfLeadingZeros() + 6) / 7).floor()));
            putUvarint(length, path.length);
            dout.add(length);
            dout.add(path);
            return Uint8List.fromList(utf8.encode(addr));
          }
        case ProtocolType.DNS:
        case ProtocolType.DNS4:
        case ProtocolType.DNS6:
        case ProtocolType.DNSADDR:
            return Uint8List.fromList(utf8.encode(addr));

        default:
          throw FormatException("Unknown multiaddr type");
      }
    } catch (e) {
      throw FormatException(e.toString());
    }
  }



  String readAddress(Uint8List addr) {
    int size = sizeForAddress(addr);
    switch (_type) {
      case ProtocolType.IP4:
        var buf = read(addr, size);
        return InternetAddress.fromRawAddress(buf).address;
      case ProtocolType.IP6:
        var buf = read(addr, size);
        return InternetAddress.fromRawAddress(buf).address;
      case ProtocolType.IP6ZONE:
        return utf8.decode(addr);
      case ProtocolType.TCP:
      case ProtocolType.UDP:
      case ProtocolType.DCCP:
      case ProtocolType.SCTP: {
        return ((addr[0] << 8) + addr[1]).toString();
      }
      case ProtocolType.P2P:
      case ProtocolType.IPFS:
        return bs.base58.encode(addr);
      case ProtocolType.ONION3: {
        var host = Uint8List.fromList(addr.getRange(0, 35).toList());
        var portBytes = Uint8List.fromList(addr.getRange(35, addr.length).toList());
        var port = ((portBytes[0] << 8) + portBytes[1]);
        return "${multibaseEncode(Multibase.base32, host).substring(1)}:$port";
      }
      case ProtocolType.UNIX: {
        return utf8.decode(addr);
      }
      case ProtocolType.DNS:
      case ProtocolType.DNS4:
      case ProtocolType.DNS6:
      case ProtocolType.DNSADDR:
        return utf8.decode(addr);
    }
    throw FormatException("Unimplemented protocol type: ${_type.name}");
  }

  Uint8List read(Uint8List source, int len) {
    return readOffsetAndLen(source, 0, len);
  }

  Uint8List readOffsetAndLen(Uint8List source, int offset, int len) {
    var total=0, r=0, buf = BytesBuilder();
    while (total < len && r != -1) {
        var start = offset + total;
        var end = start + (len - total);
        var addrBuf = source.getRange(start, end);
        r = addrBuf.isNotEmpty ? addrBuf.length : -1;
        buf.add(addrBuf.toList());
      if (r >=0) {
        total = total + r;
      }
    }

    return buf.toBytes();
  }

  int sizeForAddress(Uint8List addr) {
    if (_type.size > 0) {
      return _type.size~/8;
    }
    if (_type.size == 0) {
      return 0;
    }

    var result = decodeVarint(addr, 0);

    return result.res;
  }

  @override
  bool operator ==(Object other) {
    return other is Protocol && code == other.code;
  }

  @override
  int get hashCode => _type.hashCode;

  @override
  String toString() => _type.toString();
}



Uint8List _int32bytes(int value) =>
    Uint8List(4)..buffer.asInt32List()[0] = value;

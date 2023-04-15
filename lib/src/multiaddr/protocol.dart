import 'dart:io';
import 'dart:typed_data';
import 'package:dart_multihash/src/multihash/varint_utils.dart';
import 'protocol_map.dart';
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
    return _type == ProtocolType.unix;
  }

  String get name {
    return _type.name;
  }

  Uint8List addressToBytes(String addr) {
    if(addr.isEmpty){
      return Uint8List(0);
    }

    return _type.serializer(this, addr);
  }

  String readAddress(Uint8List addr) {
    return _type.deserializer(this, addr);
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

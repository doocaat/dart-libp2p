import 'dart:convert';
import 'dart:typed_data';

import 'package:base_x/base_x.dart';
import 'package:characters/characters.dart';

const String _base16Symbols = '0123456789abcdef';
const String _base16UpperSymbols = '0123456789ABCDEF';
const String _base32Symbols = 'abcdefghijklmnopqrstuvwxyz234567';
const String _base32UpperSymbols = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
const String _base36UpperSymbols = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
const String _base58Symbols =
    '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
const String _base64Symbols =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
const String _base64UrlSymbols =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

/// List of types currently supported in the multibase spec.
///
/// Not all base types are supported by this library.
enum Multibase {
  /// hexadecimal
  base16(
    code: 'f',
    symbols: _base16Symbols,
    translateFrom: 'ABCDEF',
    translateTo: 'abcdef',
  ),

  /// hexadecimal
  base16upper(
    code: 'F',
    symbols: _base16UpperSymbols,
    translateFrom: 'abcdef',
    translateTo: 'ABCDEF',
  ),

  /// rfc4648 case-insensitive - no padding
  base32(
    code: 'b',
    symbols: _base32Symbols,
    translateFrom: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    translateTo: 'abcdefghijklmnopqrstuvwxyz',
  ),

  /// rfc4648 case-insensitive - no padding
  base32upper(
    code: 'B',
    symbols: _base32UpperSymbols,
    translateFrom: 'abcdefghijklmnopqrstuvwxyz',
    translateTo: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
  ),

  base36(
    code: 'k',
    symbols: _base36UpperSymbols,
    translateFrom: 'abcdefghijklmnopqrstuvwxyz',
    translateTo: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
  ),

  /// base58 bitcoin
  base58btc(code: 'z', symbols: _base58Symbols),

  /// rfc4648 no padding
  base64(code: 'm', symbols: _base64Symbols),

  /// rfc4648 no padding
  base64url(code: 'u', symbols: _base64UrlSymbols),

  /// rfc4648 with padding
  base64urlpad(code: 'U', symbols: _base64UrlSymbols, padding: '=');

  /// Initialize a new multibase variant
  const Multibase({
    required final String code,
    required final String symbols,
    final String padding = '',
    final String translateFrom = '',
    final String translateTo = '',
  })  : _code = code,
        _symbols = symbols,
        _padding = padding,
        _translateFrom = translateFrom,
        _translateTo = translateTo,
        assert(
          translateTo.length == translateFrom.length,
          'Translate from/to length mismatch',
        );

  final String _code;
  final String _symbols;
  final String _padding;
  final String _translateFrom;
  final String _translateTo;

  String _encode(final Uint8List data) {
    if (_padding == '=' && _symbols == _base64UrlSymbols) {
      return base64UrlEncode(data);
    }
    final Codec<Uint8List, String> c = BaseXCodec(_symbols);
    return c.encode(data);
  }

  Uint8List _decode(final String data) {
    if (_padding == '=' && _symbols == _base64UrlSymbols) {
      // TODO(serverwentdown): Stricter base64url parser
      return base64Decode(data);
    }
    final Codec<Uint8List, String> c = BaseXCodec(_symbols);
    final String mappedData = data.replaceAllMapped(
      RegExp('[$_translateFrom]'),
      (final Match match) =>
          _translateTo[_translateFrom.indexOf(match.group(0)!)],
    );
    try {
      return c.decode(mappedData);
      // ignore: avoid_catching_errors
    } on ArgumentError catch (e) {
      throw FormatException('Input is not valid data: $e');
    }
  }

  static Multibase _fromCode(final String code) {
    for (final Multibase base in Multibase.values) {
      if (base._code == code) {
        return base;
      }
    }
    throw UnsupportedError('Unknown base code: $code');
  }
}

/// Encode the given byte list to base string
String multibaseEncode(final Multibase base, final Uint8List data) {
  final String encoded = base._encode(data);
  return base._code + encoded;
}

/// Decode the base string
Uint8List multibaseDecode(final String data) {
  final String code = data.characters.first;
  final Multibase base = Multibase._fromCode(code);
  return base._decode(data.substring(code.length));
}

/// Encoder for Multibase encoded data
class MultibaseEncoder extends Converter<Uint8List, String> {
  /// Construct a new encoder for the given base
  MultibaseEncoder(final Multibase base) : _base = base;

  final Multibase _base;

  @override
  String convert(final Uint8List input) => multibaseEncode(_base, input);
}

/// Decoder for Multibase encoded data
class MultibaseDecoder extends Converter<String, Uint8List> {
  @override
  Uint8List convert(final String input) => multibaseDecode(input);
}

/// A multibase encoder and decoder
class MultibaseCodec extends Codec<Uint8List, String> {
  /// Construct a new encoder for the given base and a generic decoder
  MultibaseCodec({required final Multibase encodeBase})
      : encoder = MultibaseEncoder(encodeBase);

  @override
  final MultibaseEncoder encoder;
  @override
  final MultibaseDecoder decoder = MultibaseDecoder();
}

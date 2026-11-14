import 'dart:typed_data';

import 'tesseract_module.dart';

/// The platform-neutral port every adapter implements. Pure Dart — the
/// transport is injected behind the platform envelope, so tests run
/// offline with fake channels.
abstract class OcrPort {
  const OcrPort();

  /// Whether the host platform can run OCR at all.
  Future<bool> isSupported();

  /// Compiles [bytes] and binds the result to [id].
  Future<TesseractModule> compile({
    required String id,
    required Uint8List bytes,
  });

  /// Invokes [export] on the compiled module [id].
  Future<List<OcrValue>> invoke({
    required String id,
    required String export,
    List<OcrValue> args = const [],
  });

  /// Releases the compiled module [id].
  Future<void> unload({required String id});
}

/// A typed value passed to and returned from OCR operations.
///
/// Wraps primitives in a way that survives JSON encoding across the
/// platform channel boundary.
class OcrValue {
  final Object? _value;

  const OcrValue._(this._value);

  /// Creates a string value.
  const OcrValue.string(String value) : _value = value;

  /// Creates an integer value.
  const OcrValue.int(int value) : _value = value;

  /// Creates a double value.
  const OcrValue.double(double value) : _value = value;

  /// Creates a boolean value.
  const OcrValue.bool(bool value) : _value = value;

  /// Creates a binary data value.
  const OcrValue.bytes(Uint8List value) : _value = value;

  /// Decodes a value from its JSON representation.
  factory OcrValue.decode(Object? json) {
    if (json == null) return const OcrValue._(null);
    if (json is String) return OcrValue.string(json);
    if (json is int) return OcrValue.int(json);
    if (json is double) return OcrValue.double(json);
    if (json is bool) return OcrValue.bool(json);
    if (json is List<int>) return OcrValue.bytes(Uint8List.fromList(json));
    throw ArgumentError.value(json, 'json', 'Unsupported OcrValue type');
  }

  /// Encodes this value to its JSON representation.
  Object? encode() => _value;

  /// Returns the underlying value.
  Object? get value => _value;

  /// Returns true if this value is a string.
  bool get isString => _value is String;

  /// Returns true if this value is an integer.
  bool get isInt => _value is int;

  /// Returns true if this value is a double.
  bool get isDouble => _value is double;

  /// Returns true if this value is a boolean.
  bool get isBool => _value is bool;

  /// Returns true if this value is binary data.
  bool get isBytes => _value is Uint8List;

  /// Returns the string value, or null if this is not a string.
  String? get asString => _value as String?;

  /// Returns the integer value, or null if this is not an integer.
  int? get asInt => _value as int?;

  /// Returns the double value, or null if this is not a double.
  double? get asDouble => _value as double?;

  /// Returns the boolean value, or null if this is not a boolean.
  bool? get asBool => _value as bool?;

  /// Returns the bytes value, or null if this is not binary data.
  Uint8List? get asBytes => _value as Uint8List?;

  @override
  String toString() => 'OcrValue($_value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OcrValue &&
          runtimeType == other.runtimeType &&
          _value == other._value;

  @override
  int get hashCode => _value.hashCode;
}
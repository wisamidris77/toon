import 'constants.dart' as constants;

/// Represents primitive JSON values
typedef JsonPrimitive = Object?; // null, String, num, bool

/// Represents JSON objects (maps from strings to JSON values)
typedef JsonObject = Map<String, Object?>;

/// Represents JSON arrays
typedef JsonArray = List<Object?>;

/// Represents any valid JSON value
typedef JsonValue = Object?; // JsonPrimitive | JsonObject | JsonArray

// #endregion

// #region Encoder options

/// Represents delimiter keys
typedef DelimiterKey = String;

/// Represents valid delimiter values
typedef Delimiter = String;

/// Options for encoding Toon format
class EncodeOptions {
  /// Number of spaces per indentation level.
  /// @default 2
  final int indent;

  /// Delimiter to use for tabular array rows and inline primitive arrays.
  /// @default DELIMITERS.comma
  final Delimiter delimiter;

  /// Optional marker to prefix array lengths in headers.
  /// When set to `#`, arrays render as [#N] instead of [N].
  /// @default false
  final String? lengthMarker;

  const EncodeOptions({
    this.indent = 2,
    Delimiter? delimiter,
    this.lengthMarker,
  }) : delimiter = delimiter ?? constants.COMMA;
}

/// Resolved encode options with all defaults applied
typedef ResolvedEncodeOptions = EncodeOptions;

// #endregion

// #region Decoder options

/// Options for decoding Toon format
class DecodeOptions {
  /// Number of spaces per indentation level.
  /// @default 2
  final int indent;

  /// When true, enforce strict validation of array lengths and tabular row counts.
  /// @default true
  final bool strict;

  const DecodeOptions({
    this.indent = 2,
    this.strict = true,
  });
}

/// Resolved decode options with all defaults applied
typedef ResolvedDecodeOptions = DecodeOptions;

// #endregion

// #region Decoder parsing types

/// Information about an array header
class ArrayHeaderInfo {
  final String? key;
  final int length;
  final Delimiter delimiter;
  final List<String>? fields;
  final bool hasLengthMarker;

  const ArrayHeaderInfo({
    this.key,
    required this.length,
    required this.delimiter,
    this.fields,
    this.hasLengthMarker = false,
  });
}

/// Represents a parsed line from the source
class ParsedLine {
  final String raw;
  final int depth;
  final int indent;
  final String content;
  final int lineNumber;

  const ParsedLine({
    required this.raw,
    required this.depth,
    required this.indent,
    required this.content,
    required this.lineNumber,
  });
}

/// Information about blank lines
class BlankLineInfo {
  final int lineNumber;
  final int indent;
  final int depth;

  const BlankLineInfo({
    required this.lineNumber,
    required this.indent,
    required this.depth,
  });
}

// #endregion

/// Represents depth in the parsing tree
typedef Depth = int;

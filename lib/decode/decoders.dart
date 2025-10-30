import '../constants.dart';
import '../types.dart';
import '../shared/string-utils.dart';
import 'parser.dart';
import 'scanner.dart';
import 'validation.dart';

// #region Entry decoding

/// Decodes a Toon-formatted string to JsonValue
Object? decodeValueFromLines(LineCursor cursor, ResolvedDecodeOptions options) {
  final first = cursor.peek();
  if (first == null) {
    throw StateError('No content to decode');
  }

  // Check for root array
  if (isArrayHeaderAfterHyphen(first.content)) {
    final headerInfo = parseArrayHeaderLine(first.content, DEFAULT_DELIMITER);
    if (headerInfo != null) {
      cursor.advance(); // Move past the header line
      return decodeArrayFromHeader(headerInfo.header, headerInfo.inlineValues, cursor, 0, options);
    }
  }

  // Check for single primitive value
  if (cursor.length == 1 && !_isKeyValueLine(first)) {
    return parsePrimitiveToken(first.content.trim());
  }

  // Default to object
  return decodeObject(cursor, 0, options);
}

bool _isKeyValueLine(ParsedLine line) {
  final content = line.content;
  // Look for unquoted colon or quoted key followed by colon
  if (content.startsWith(DOUBLE_QUOTE)) {
    // Quoted key - find the closing quote
    final closingQuoteIndex = findClosingQuote(content, 0);
    if (closingQuoteIndex == -1) {
      return false;
    }
    // Check if there's a colon after the quoted key
    return closingQuoteIndex + 1 < content.length && content[closingQuoteIndex + 1] == COLON;
  } else {
    // Unquoted key - look for first colon not inside quotes
    return content.contains(COLON);
  }
}

// #endregion

// #region Object decoding

/// Decodes an object from the cursor
Map<String, Object?> decodeObject(LineCursor cursor, int baseDepth, ResolvedDecodeOptions options) {
  final obj = <String, Object?>{};

  while (!cursor.atEnd()) {
    final line = cursor.peek();
    if (line == null || line.depth < baseDepth) {
      break;
    }

    if (line.depth == baseDepth) {
      final (key, value) = decodeKeyValuePair(line, cursor, baseDepth, options);
      obj[key] = value;
    } else {
      break;
    }
  }

  return obj;
}

/// Decodes key-value data
({String key, Object? value, int followDepth}) _decodeKeyValue(
  String content,
  LineCursor cursor,
  int baseDepth,
  ResolvedDecodeOptions options,
) {
  // Check for array header first (before parsing key)
  final arrayHeader = parseArrayHeaderLine(content, DEFAULT_DELIMITER);
  if (arrayHeader != null && arrayHeader.header.key != null) {
    final value = decodeArrayFromHeader(arrayHeader.header, arrayHeader.inlineValues, cursor, baseDepth, options);
    // After an array, subsequent fields are at baseDepth + 1 (where array content is)
    return (key: arrayHeader.header.key!, value: value, followDepth: baseDepth + 1);
  }

  // Regular key-value pair
  final keyToken = parseKeyToken(content, 0);
  final rest = content.substring(keyToken.end).trim();

  // No value after colon - expect nested object or empty
  if (rest.isEmpty) {
    final nextLine = cursor.peek();
    if (nextLine != null && nextLine.depth > baseDepth) {
      final nested = decodeObject(cursor, baseDepth + 1, options);
      return (key: keyToken.key, value: nested, followDepth: baseDepth + 1);
    }
    // Empty object
    return (key: keyToken.key, value: <String, Object?>{}, followDepth: baseDepth + 1);
  }

  // Inline primitive value
  final value = parsePrimitiveToken(rest);
  return (key: keyToken.key, value: value, followDepth: baseDepth + 1);
}

/// Decodes a key-value pair
(String, Object?) decodeKeyValuePair(
  ParsedLine line,
  LineCursor cursor,
  int baseDepth,
  ResolvedDecodeOptions options,
) {
  cursor.advance();
  final kv = _decodeKeyValue(line.content, cursor, baseDepth, options);
  return (kv.key, kv.value);
}

// #endregion

// #region Array decoding

/// Decodes an array from header information
List<Object?> decodeArrayFromHeader(
  ArrayHeaderInfo header,
  String? inlineValues,
  LineCursor cursor,
  int baseDepth,
  ResolvedDecodeOptions options,
) {
  // Inline primitive array
  if (inlineValues != null) {
    // For inline arrays, cursor should already be advanced or will be by caller
    return decodeInlinePrimitiveArray(header, inlineValues, options);
  }

  // For multi-line arrays (tabular or list), the cursor should already be positioned
  // at the array header line, but we haven't advanced past it yet

  // Tabular array
  if (header.fields != null && header.fields!.isNotEmpty) {
    return decodeTabularArray(header, cursor, baseDepth, options);
  }

  // List array
  return decodeListArray(header, cursor, baseDepth, options);
}

/// Decodes an inline primitive array
List<Object?> decodeInlinePrimitiveArray(
  ArrayHeaderInfo header,
  String inlineValues,
  ResolvedDecodeOptions options,
) {
  if (inlineValues.trim().isEmpty) {
    assertExpectedCount(0, header.length, 'inline array items', options);
    return [];
  }

  final values = parseDelimitedValues(inlineValues, header.delimiter);
  final primitives = mapRowValuesToPrimitives(values);

  assertExpectedCount(primitives.length, header.length, 'inline array items', options);

  return primitives;
}

/// Decodes a list array
List<Object?> decodeListArray(
  ArrayHeaderInfo header,
  LineCursor cursor,
  int baseDepth,
  ResolvedDecodeOptions options,
) {
  final items = <Object?>[];
  final itemDepth = baseDepth + 1;

  // Track line range for blank line validation
  int? startLine;
  int? endLine;

  while (!cursor.atEnd() && items.length < header.length) {
    final line = cursor.peek();
    if (line == null || line.depth < itemDepth) {
      break;
    }

    if (line.depth == itemDepth && line.content.startsWith(LIST_ITEM_PREFIX)) {
      // Track first and last item line numbers
      if (startLine == null) {
        startLine = line.lineNumber;
      }
      endLine = line.lineNumber;

      final item = decodeListItem(cursor, itemDepth, header.delimiter, options);
      items.add(item);

      // Update endLine to the current cursor position (after item was decoded)
      final currentLine = cursor.current();
      if (currentLine != null) {
        endLine = currentLine.lineNumber;
      }
    } else {
      break;
    }
  }

  assertExpectedCount(items.length, header.length, 'list array items', options);

  // In strict mode, check for blank lines inside the array
  if (options.strict && startLine != null && endLine != null) {
    validateNoBlankLinesInRange(
      startLine, // From first item line
      endLine, // To last item line
      cursor.getBlankLines(),
      options.strict,
      'list array',
    );
  }

  // In strict mode, check for extra items
  if (options.strict) {
    validateNoExtraListItems(cursor, itemDepth, header.length);
  }

  return items;
}

/// Decodes a tabular array
List<Map<String, Object?>> decodeTabularArray(
  ArrayHeaderInfo header,
  LineCursor cursor,
  int baseDepth,
  ResolvedDecodeOptions options,
) {
  final objects = <Map<String, Object?>>[];
  final rowDepth = baseDepth + 1;

  // Track line range for blank line validation
  int? startLine;
  int? endLine;

  while (!cursor.atEnd() && objects.length < header.length) {
    final line = cursor.peek();
    if (line == null || line.depth < rowDepth) {
      break;
    }

    if (line.depth == rowDepth) {
      // Track first and last row line numbers
      if (startLine == null) {
        startLine = line.lineNumber;
      }
      endLine = line.lineNumber;

      cursor.advance();
      final values = parseDelimitedValues(line.content, header.delimiter);
      assertExpectedCount(values.length, header.fields!.length, 'tabular row values', options);

      final primitives = mapRowValuesToPrimitives(values);
      final obj = <String, Object?>{};

      for (int i = 0; i < header.fields!.length; i++) {
        obj[header.fields![i]] = primitives[i];
      }

      objects.add(obj);
    } else {
      break;
    }
  }

  assertExpectedCount(objects.length, header.length, 'tabular rows', options);

  // In strict mode, check for blank lines inside the array
  if (options.strict && startLine != null && endLine != null) {
    validateNoBlankLinesInRange(
      startLine, // From first row line
      endLine, // To last row line
      cursor.getBlankLines(),
      options.strict,
      'tabular array',
    );
  }

  // In strict mode, check for extra rows
  if (options.strict) {
    validateNoExtraTabularRows(cursor, rowDepth, header);
  }

  return objects;
}

// #endregion

// #region List item decoding

/// Decodes a list item
Object? decodeListItem(
  LineCursor cursor,
  int baseDepth,
  String activeDelimiter,
  ResolvedDecodeOptions options,
) {
  final line = cursor.next();
  if (line == null) {
    throw StateError('Expected list item');
  }

  final afterHyphen = line.content.substring(LIST_ITEM_PREFIX.length);

  // Check for array header after hyphen
  if (isArrayHeaderAfterHyphen(afterHyphen)) {
    final arrayHeader = parseArrayHeaderLine(afterHyphen, DEFAULT_DELIMITER);
    if (arrayHeader != null) {
      return decodeArrayFromHeader(arrayHeader.header, arrayHeader.inlineValues, cursor, baseDepth, options);
    }
  }

  // Check for object first field after hyphen
  if (isObjectFirstFieldAfterHyphen(afterHyphen)) {
    return decodeObjectFromListItem(line, cursor, baseDepth, options);
  }

  // Primitive value
  return parsePrimitiveToken(afterHyphen);
}

/// Decodes an object from a list item
Map<String, Object?> decodeObjectFromListItem(
  ParsedLine firstLine,
  LineCursor cursor,
  int baseDepth,
  ResolvedDecodeOptions options,
) {
  final afterHyphen = firstLine.content.substring(LIST_ITEM_PREFIX.length);
  final kv = _decodeKeyValue(afterHyphen, cursor, baseDepth, options);

  final obj = <String, Object?>{kv.key: kv.value};

  // Read subsequent fields
  while (!cursor.atEnd()) {
    final line = cursor.peek();
    if (line == null || line.depth < kv.followDepth) {
      break;
    }

    if (line.depth == kv.followDepth && !line.content.startsWith(LIST_ITEM_PREFIX)) {
      final (k, v) = decodeKeyValuePair(line, cursor, kv.followDepth, options);
      obj[k] = v;
    } else {
      break;
    }
  }

  return obj;
}

// #endregion

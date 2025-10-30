import '../constants.dart';
import '../types.dart';
import 'normalize.dart';
import 'primitives.dart';
import 'writer.dart';

/// Encodes a normalized JsonValue to Toon format
String encodeValue(Object? value, ResolvedEncodeOptions options) {
  if (isJsonPrimitive(value)) {
    return encodePrimitive(value, options.delimiter);
  }

  final writer = LineWriter(options.indent);

  if (isJsonArray(value)) {
    encodeArray(null, value as List<Object?>, writer, 0, options);
  } else if (isJsonObject(value)) {
    encodeObject(value as Map<String, Object?>, writer, 0, options);
  }

  return writer.toString();
}

/// Encodes an object to Toon format
void encodeObject(Map<String, Object?> value, LineWriter writer, int depth,
    ResolvedEncodeOptions options) {
  final keys = value.keys;

  for (final key in keys) {
    encodeKeyValuePair(key, value[key], writer, depth, options);
  }
}

/// Encodes a key-value pair
void encodeKeyValuePair(String key, Object? value, LineWriter writer, int depth,
    ResolvedEncodeOptions options) {
  final encodedKey = encodeKey(key);

  if (isJsonPrimitive(value)) {
    writer.push(
        depth, '$encodedKey: ${encodePrimitive(value, options.delimiter)}');
  } else if (isJsonArray(value)) {
    encodeArray(key, value as List<Object?>, writer, depth, options);
  } else if (isJsonObject(value)) {
    final nestedKeys = (value as Map<String, Object?>).keys;
    if (nestedKeys.isEmpty) {
      // Empty object
      writer.push(depth, '$encodedKey:');
    } else {
      writer.push(depth, '$encodedKey:');
      encodeObject(value, writer, depth + 1, options);
    }
  }
}

/// Encodes an array
void encodeArray(String? key, List<Object?> value, LineWriter writer, int depth,
    ResolvedEncodeOptions options) {
  if (value.isEmpty) {
    final header = formatHeader(0,
        key: key,
        delimiter: options.delimiter,
        lengthMarker: options.lengthMarker);
    writer.push(depth, header);
    return;
  }

  // Primitive array
  if (isArrayOfPrimitives(value)) {
    final formatted = encodeInlineArrayLine(
        value, options.delimiter, key, options.lengthMarker);
    writer.push(depth, formatted);
    return;
  }

  // Array of arrays (all primitives)
  if (isArrayOfArrays(value)) {
    final allPrimitiveArrays =
        value.every((arr) => isArrayOfPrimitives(arr as List<Object?>));
    if (allPrimitiveArrays) {
      encodeArrayOfArraysAsListItems(
          key, value.cast<List<Object?>>(), writer, depth, options);
      return;
    }
  }

  // Array of objects
  if (isArrayOfObjects(value)) {
    final header = extractTabularHeader(value.cast<Map<String, Object?>>());
    if (header != null) {
      encodeArrayOfObjectsAsTabular(key, value.cast<Map<String, Object?>>(),
          header, writer, depth, options);
    } else {
      encodeMixedArrayAsListItems(key, value, writer, depth, options);
    }
    return;
  }

  // Mixed array: fallback to expanded format
  encodeMixedArrayAsListItems(key, value, writer, depth, options);
}

/// Encodes an array of arrays as list items
void encodeArrayOfArraysAsListItems(
  String? prefix,
  List<List<Object?>> values,
  LineWriter writer,
  int depth,
  ResolvedEncodeOptions options,
) {
  final header = formatHeader(values.length,
      key: prefix,
      delimiter: options.delimiter,
      lengthMarker: options.lengthMarker);
  writer.push(depth, header);

  for (final arr in values) {
    if (isArrayOfPrimitives(arr)) {
      final inline = encodeInlineArrayLine(
          arr, options.delimiter, null, options.lengthMarker);
      writer.pushListItem(depth + 1, inline);
    }
  }
}

/// Encodes a single line array of primitives
String encodeInlineArrayLine(List<Object?> values, String delimiter,
    String? prefix, String? lengthMarker) {
  final header = formatHeader(values.length,
      key: prefix, delimiter: delimiter, lengthMarker: lengthMarker);
  final joinedValue = encodeAndJoinPrimitives(values, delimiter);
  // Only add space if there are values
  if (values.isEmpty) {
    return header;
  }
  return '$header $joinedValue';
}

/// Encodes an array of objects in tabular format
void encodeArrayOfObjectsAsTabular(
  String? prefix,
  List<Map<String, Object?>> rows,
  List<String> header,
  LineWriter writer,
  int depth,
  ResolvedEncodeOptions options,
) {
  final formattedHeader = formatHeader(rows.length,
      key: prefix,
      fields: header,
      delimiter: options.delimiter,
      lengthMarker: options.lengthMarker);
  writer.push(depth, formattedHeader);

  writeTabularRows(rows, header, writer, depth + 1, options);
}

/// Extracts tabular header from array of objects
List<String>? extractTabularHeader(List<Map<String, Object?>> rows) {
  if (rows.isEmpty) {
    return null;
  }

  final firstRow = rows[0];
  final firstKeys = firstRow.keys.toList();
  if (firstKeys.isEmpty) {
    return null;
  }

  if (isTabularArray(rows, firstKeys)) {
    return firstKeys;
  }

  return null;
}

/// Checks if an array can be represented as a tabular format
bool isTabularArray(List<Map<String, Object?>> rows, List<String> header) {
  for (final row in rows) {
    final keys = row.keys;

    // All objects must have the same keys (but order can differ)
    if (keys.length != header.length) {
      return false;
    }

    // Check that all header keys exist in the row and all values are primitives
    for (final key in header) {
      if (!row.containsKey(key)) {
        return false;
      }
      if (!isJsonPrimitive(row[key])) {
        return false;
      }
    }
  }

  return true;
}

/// Writes tabular rows
void writeTabularRows(
  List<Map<String, Object?>> rows,
  List<String> header,
  LineWriter writer,
  int depth,
  ResolvedEncodeOptions options,
) {
  for (final row in rows) {
    final values = header.map((key) => row[key]);
    final joinedValue =
        encodeAndJoinPrimitives(values.toList(), options.delimiter);
    writer.push(depth, joinedValue);
  }
}

/// Encodes a mixed array as list items
void encodeMixedArrayAsListItems(
  String? prefix,
  List<Object?> items,
  LineWriter writer,
  int depth,
  ResolvedEncodeOptions options,
) {
  final header = formatHeader(items.length,
      key: prefix,
      delimiter: options.delimiter,
      lengthMarker: options.lengthMarker);
  writer.push(depth, header);

  for (final item in items) {
    encodeListItemValue(item, writer, depth + 1, options);
  }
}

/// Encodes an object as a list item
void encodeObjectAsListItem(Map<String, Object?> obj, LineWriter writer,
    int depth, ResolvedEncodeOptions options) {
  final keys = obj.keys.toList();
  if (keys.isEmpty) {
    writer.push(depth, listItemMarker);
    return;
  }

  // First key-value on the same line as "- "
  final firstKey = keys[0];
  final encodedKey = encodeKey(firstKey);
  final firstValue = obj[firstKey];

  if (isJsonPrimitive(firstValue)) {
    writer.pushListItem(depth,
        '$encodedKey: ${encodePrimitive(firstValue, options.delimiter)}');
  } else if (isJsonArray(firstValue)) {
    final firstValueList = firstValue as List<Object?>;
    if (isArrayOfPrimitives(firstValueList)) {
      // Inline format for primitive arrays
      final formatted = encodeInlineArrayLine(
          firstValueList, options.delimiter, firstKey, options.lengthMarker);
      writer.pushListItem(depth, formatted);
    } else if (isArrayOfObjects(firstValueList)) {
      // Check if array of objects can use tabular format
      final header =
          extractTabularHeader(firstValueList.cast<Map<String, Object?>>());
      if (header != null) {
        // Tabular format for uniform arrays of objects
        final formattedHeader = formatHeader(firstValueList.length,
            key: firstKey,
            fields: header,
            delimiter: options.delimiter,
            lengthMarker: options.lengthMarker);
        writer.pushListItem(depth, formattedHeader);
        writeTabularRows(firstValueList.cast<Map<String, Object?>>(), header,
            writer, depth + 1, options);
      } else {
        // Fall back to list format for non-uniform arrays of objects
        writer.pushListItem(depth, '$encodedKey[${firstValueList.length}]:');
        for (final item in firstValueList) {
          encodeObjectAsListItem(
              item as Map<String, Object?>, writer, depth + 1, options);
        }
      }
    } else {
      // Complex arrays on separate lines (array of arrays, etc.)
      writer.pushListItem(depth, '$encodedKey[${firstValueList.length}]:');

      // Encode array contents at depth + 1
      for (final item in firstValueList) {
        encodeListItemValue(item, writer, depth + 1, options);
      }
    }
  } else if (isJsonObject(firstValue)) {
    final nestedKeys = (firstValue as Map<String, Object?>).keys;
    if (nestedKeys.isEmpty) {
      writer.pushListItem(depth, '$encodedKey:');
    } else {
      writer.pushListItem(depth, '$encodedKey:');
      encodeObject(firstValue, writer, depth + 2, options);
    }
  }

  // Remaining keys on indented lines
  for (int i = 1; i < keys.length; i++) {
    final key = keys[i];
    encodeKeyValuePair(key, obj[key], writer, depth + 1, options);
  }
}

/// Encodes a list item value
void encodeListItemValue(Object? value, LineWriter writer, int depth,
    ResolvedEncodeOptions options) {
  if (isJsonPrimitive(value)) {
    writer.pushListItem(depth, encodePrimitive(value, options.delimiter));
  } else if (isJsonArray(value)) {
    final valueList = value as List<Object?>;
    if (isArrayOfPrimitives(valueList)) {
      final inline = encodeInlineArrayLine(
          valueList, options.delimiter, null, options.lengthMarker);
      writer.pushListItem(depth, inline);
    }
  } else if (isJsonObject(value)) {
    encodeObjectAsListItem(
        value as Map<String, Object?>, writer, depth, options);
  }
}

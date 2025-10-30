/// Normalizes any Dart value to a valid JsonValue for encoding
Object? normalizeValue(Object? value) {
  // null
  if (value == null) {
    return null;
  }

  // Primitives
  if (value is String || value is bool) {
    return value;
  }

  // Numbers: canonicalize -0 to 0, handle NaN and Infinity
  if (value is num) {
    if (value == -0.0) {
      return 0;
    }
    if (!value.isFinite) {
      return null;
    }
    return value;
  }

  // BigInt → number (if safe) or string
  if (value is BigInt) {
    // Try to convert to number if within safe integer range
    if (value >= BigInt.from(-9007199254740991) &&
        value <= BigInt.from(9007199254740991)) {
      return value.toInt();
    }
    // Otherwise convert to string (will be unquoted as it looks numeric)
    return value.toString();
  }

  // DateTime → ISO string
  if (value is DateTime) {
    return value.toIso8601String();
  }

  // List
  if (value is List) {
    return value.map(normalizeValue).toList();
  }

  // Set → array
  if (value is Set) {
    return value.map(normalizeValue).toList();
  }

  // Map → object (convert keys to strings)
  if (value is Map) {
    final Map<String, Object?> result = {};
    for (final entry in value.entries) {
      final String key = entry.key.toString();
      result[key] = normalizeValue(entry.value);
    }
    return result;
  }

  // Plain object (other objects) - in Dart, we can't easily introspect like in JS
  // For now, just return null for unknown objects
  // This is different from the TypeScript version which uses plain object detection

  // Fallback: function, symbol, undefined, or other → null
  return null;
}

/// Checks if a value is a JSON primitive
bool isJsonPrimitive(Object? value) {
  return value == null || value is String || value is num || value is bool;
}

/// Checks if a value is a JSON array
bool isJsonArray(Object? value) {
  return value is List;
}

/// Checks if a value is a JSON object
bool isJsonObject(Object? value) {
  return value != null && value is Map<String, Object?>;
}

/// Checks if an array contains only primitives
bool isArrayOfPrimitives(List<Object?> value) {
  return value.every(isJsonPrimitive);
}

/// Checks if an array contains only arrays
bool isArrayOfArrays(List<Object?> value) {
  return value.every(isJsonArray);
}

/// Checks if an array contains only objects
bool isArrayOfObjects(List<Object?> value) {
  return value.every(isJsonObject);
}

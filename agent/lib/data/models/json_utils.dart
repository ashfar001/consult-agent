/// Small helpers for tolerant JSON decoding of API payloads.
typedef Json = Map<String, dynamic>;

int asInt(Object? v, [int fallback = 0]) => switch (v) {
  final int i => i,
  final num n => n.round(),
  final String s => int.tryParse(s) ?? fallback,
  _ => fallback,
};

double asDouble(Object? v, [double fallback = 0]) => switch (v) {
  final num n => n.toDouble(),
  final String s => double.tryParse(s) ?? fallback,
  _ => fallback,
};

String asString(Object? v, [String fallback = '']) =>
    v == null ? fallback : v.toString();

String? asStringOrNull(Object? v) => v?.toString();

DateTime asDate(Object? v) => DateTime.parse(asString(v)).toLocal();

List<Json> asJsonList(Object? v) =>
    v is List ? v.whereType<Map<String, dynamic>>().toList() : const [];

Map<String, int> asIntMap(Object? v) => v is Map
    ? {for (final e in v.entries) e.key.toString(): asInt(e.value)}
    : const {};

/// UTC ISO-8601 for the wire.
String isoUtc(DateTime t) => t.toUtc().toIso8601String();

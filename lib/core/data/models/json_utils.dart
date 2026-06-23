String? readString(Map<String, dynamic>? json, List<String> keys) {
  if (json == null) return null;
  for (final k in keys) {
    final v = json[k];
    if (v == null) continue;
    if (v is String && v.trim().isEmpty) continue;
    return v.toString();
  }
  return null;
}

int? readInt(Map<String, dynamic>? json, List<String> keys) {
  if (json == null) return null;
  for (final k in keys) {
    final v = json[k];
    if (v == null) continue;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      final parsed = int.tryParse(v);
      if (parsed != null) return parsed;
    }
  }
  return null;
}

double? readDouble(Map<String, dynamic>? json, List<String> keys) {
  if (json == null) return null;
  for (final k in keys) {
    final v = json[k];
    if (v == null) continue;
    if (v is num) return v.toDouble();
    if (v is String) {
      final parsed = double.tryParse(v);
      if (parsed != null) return parsed;
    }
  }
  return null;
}

bool? readBool(Map<String, dynamic>? json, List<String> keys) {
  if (json == null) return null;
  for (final k in keys) {
    final v = json[k];
    if (v == null) continue;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.toLowerCase().trim();
      if (s == 'true' || s == '1' || s == 'yes') return true;
      if (s == 'false' || s == '0' || s == 'no') return false;
    }
  }
  return null;
}

DateTime? readDate(Map<String, dynamic>? json, List<String> keys) {
  if (json == null) return null;
  for (final k in keys) {
    final v = json[k];
    if (v == null) continue;
    if (v is DateTime) return v;
    if (v is String && v.isNotEmpty) {
      final parsed = DateTime.tryParse(v);
      if (parsed != null) return parsed;
    }
  }
  return null;
}

List<String> readStringList(Map<String, dynamic>? json, List<String> keys) {
  if (json == null) return const [];
  for (final k in keys) {
    final v = json[k];
    if (v is List) {
      return v.map((e) => e.toString()).toList();
    }
    if (v is String && v.isNotEmpty) {
      return v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
  }
  return const [];
}

List<Map<String, dynamic>> readListPayload(dynamic payload) {
  if (payload is List) {
    return payload.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }
  if (payload is Map<String, dynamic>) {
    for (final key in ['data', 'results', 'items']) {
      final v = payload[key];
      if (v is List) {
        return v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      }
    }
  }
  return const [];
}

Map<String, dynamic>? readObjectPayload(dynamic payload) {
  if (payload is Map<String, dynamic>) {
    final data = payload['data'];
    if (data is Map<String, dynamic>) return data;
    return payload;
  }
  return null;
}

Map<String, dynamic>? readObject(Map<String, dynamic>? json, String key) {
  if (json == null) return null;
  final value = json[key];
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return null;
}

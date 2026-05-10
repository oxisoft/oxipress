import 'package:shared_preferences/shared_preferences.dart';

/// Pluggable key-value storage. Backed by `SharedPreferences` in production;
/// tests use [InMemoryStorage] via Riverpod overrides.
abstract interface class Storage {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);

  Future<bool?> getBool(String key);
  Future<void> setBool(String key, bool value);

  Future<int?> getInt(String key);
  Future<void> setInt(String key, int value);

  Future<double?> getDouble(String key);
  Future<void> setDouble(String key, double value);

  Future<List<String>?> getStringList(String key);
  Future<void> setStringList(String key, List<String> value);

  Future<void> remove(String key);
  Future<bool> containsKey(String key);
  Future<void> clear();
}

class SharedPreferencesStorage implements Storage {
  SharedPreferencesStorage(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<String?> getString(String key) async => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  @override
  Future<bool?> getBool(String key) async => _prefs.getBool(key);

  @override
  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  @override
  Future<int?> getInt(String key) async => _prefs.getInt(key);

  @override
  Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  @override
  Future<double?> getDouble(String key) async => _prefs.getDouble(key);

  @override
  Future<void> setDouble(String key, double value) async {
    await _prefs.setDouble(key, value);
  }

  @override
  Future<List<String>?> getStringList(String key) async =>
      _prefs.getStringList(key);

  @override
  Future<void> setStringList(String key, List<String> value) async {
    await _prefs.setStringList(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  @override
  Future<bool> containsKey(String key) async => _prefs.containsKey(key);

  @override
  Future<void> clear() async {
    await _prefs.clear();
  }
}

class InMemoryStorage implements Storage {
  InMemoryStorage([Map<String, Object?>? initial])
      : _values = {...?initial};

  final Map<String, Object?> _values;

  @override
  Future<String?> getString(String key) async => _values[key] as String?;

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<bool?> getBool(String key) async => _values[key] as bool?;

  @override
  Future<void> setBool(String key, bool value) async {
    _values[key] = value;
  }

  @override
  Future<int?> getInt(String key) async => _values[key] as int?;

  @override
  Future<void> setInt(String key, int value) async {
    _values[key] = value;
  }

  @override
  Future<double?> getDouble(String key) async => _values[key] as double?;

  @override
  Future<void> setDouble(String key, double value) async {
    _values[key] = value;
  }

  @override
  Future<List<String>?> getStringList(String key) async =>
      (_values[key] as List<dynamic>?)?.cast<String>();

  @override
  Future<void> setStringList(String key, List<String> value) async {
    _values[key] = List<String>.unmodifiable(value);
  }

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }

  @override
  Future<bool> containsKey(String key) async => _values.containsKey(key);

  @override
  Future<void> clear() async {
    _values.clear();
  }
}

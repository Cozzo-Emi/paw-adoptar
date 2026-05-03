class TokenStorage {
  static final Map<String, String> _store = {};

  Future<String?> read({required String key}) async {
    return _store[key];
  }

  Future<void> write({required String key, required String value}) async {
    _store[key] = value;
  }

  Future<void> deleteAll() async {
    _store.clear();
  }
}

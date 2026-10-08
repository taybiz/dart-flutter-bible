/// Fake third-party client that throws raw exceptions, like every HTTP/DB SDK does.
///
/// Stands in for `http.Client`, a drift executor, etc.: third-party code whose
/// failure mode is `throw`, not a typed value. Adapters exist to isolate this.
class ThrowingHttpClient {
  /// Failures the client throws, keyed by request token, in throw order.
  final Map<String, List<Exception>> scripted = {};

  /// Returns canned data, or throws the next scripted [Exception] for [token].
  Future<Map<String, Object?>> fetch({required String token}) async {
    final queued = scripted[token];
    if (queued != null && queued.isNotEmpty) throw queued.removeAt(0);
    return <String, Object?>{'id': token, 'holder': 'Ada'};
  }
}

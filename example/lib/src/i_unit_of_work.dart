/// Transaction seam — transactional adapters implement it over their store.
abstract interface class IUnitOfWork {
  /// Runs [work] inside the store's transaction.
  Future<T> run<T>(Future<T> Function() work);
}

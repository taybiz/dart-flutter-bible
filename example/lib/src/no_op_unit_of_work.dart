import 'i_unit_of_work.dart';

/// A unit of work that runs immediately — for non-transactional stores.
class NoOpUnitOfWork implements IUnitOfWork {
  /// Creates a no-op unit of work.
  const NoOpUnitOfWork();

  @override
  Future<T> run<T>(Future<T> Function() work) => work();
}

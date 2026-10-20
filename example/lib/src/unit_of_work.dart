import 'package:fpdart/fpdart.dart';

/// Transaction seam — a transactional adapter implements it over its store.
///
/// A **function**, not a class: take a body, run it, answer with the body's own
/// `Either`. It is `Either`-aware because rollback is a value here, not an
/// exception — a body that fails answers `Left` and the adapter undoes the
/// writes, so nothing in the ring throws. `F` is the *caller's* failure type, so
/// an operation keeps its own failures inside an app's unit of work.
///
/// A transactional adapter writes one as a closure over its client, checked
/// against this type at the exact signature. See §5.6 for what it owes the seam.
typedef UnitOfWork =
    Future<Either<F, T>> Function<F, T>({
      required Future<Either<F, T>> Function() body,
    });

/// The unit of work for a store that cannot roll back: it just runs the body.
///
/// This is what a memory or JSON store is wired with at the composition root —
/// stated, never defaulted. Nothing is promised here that the store cannot do:
/// the body runs, and its atomicity is whatever the store has.
Future<Either<F, T>> noOpUnitOfWork<F, T>({
  required Future<Either<F, T>> Function() body,
}) => body();

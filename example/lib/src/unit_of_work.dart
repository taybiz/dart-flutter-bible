import 'package:fpdart/fpdart.dart';

/// Transaction seam — a transactional adapter implements it over its store.
///
/// A **function**, not a class: take a body, run it, answer with the body's own
/// `Either`. It is `Either`-aware on purpose — rollback is a value, not an
/// exception, so a body that fails answers `Left` and the adapter undoes the
/// writes; nothing in the ring throws.
///
/// Generic in `F` and `T` on purpose: `F` is the *caller's* failure type, so an
/// operation can run inside an app's own unit of work and keep its failures, and
/// `T` can carry a value back out of the transaction.
///
/// A transactional adapter writes one as a closure over its client — and it is
/// checked against this type where it is handed over, at the exact signature.
/// See §5.6 for what such an adapter owes the seam.
typedef UnitOfWork =
    Future<Either<F, T>> Function<F, T>({
      required Future<Either<F, T>> Function() body,
    });

/// The unit of work for a store that cannot roll back: it just runs the body.
///
/// This is what a memory or JSON store is wired with at the composition root —
/// out loud, never as a default. It is the honest implementation rather than a
/// silent success: a half-finished write is possible, and the store's atomicity,
/// or its absence, is what the caller gets.
Future<Either<F, T>> noOpUnitOfWork<F, T>({
  required Future<Either<F, T>> Function() body,
}) => body();

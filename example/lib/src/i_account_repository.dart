import 'package:fpdart/fpdart.dart';

import 'account.dart';
import 'account_failure.dart';

/// Repository contract — lives in the domain package; adapters implement it.
///
/// Nothing here knows about transactions: the seam sits on the operation that
/// needs one (§5.5), so an implementer writes these methods and asks no
/// questions about who owns a unit of work.
abstract interface class IAccountRepository {
  /// Returns the account with [id].
  Future<Either<AccountFailure, Account>> get({required String id});

  /// Creates an account.
  Future<Either<AccountFailure, Account>> create({
    required String id,
    required String holder,
  });
}

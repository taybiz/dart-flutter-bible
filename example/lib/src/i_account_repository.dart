import 'package:fpdart/fpdart.dart';

import 'account.dart';
import 'account_failure.dart';

/// Repository contract — lives in the domain package; adapters implement it.
///
/// Nothing here knows about transactions: the seam sits on the operation that
/// needs one (§5.5), so an implementer writes these methods without knowing who
/// owns a unit of work.
abstract interface class IAccountRepository {
  /// Returns the account with [accountHandle].
  Future<Either<AccountFailure, Account>> get({required String accountHandle});

  /// Creates an account.
  Future<Either<AccountFailure, Account>> create({
    required String accountHandle,
    required String holder,
  });
}

import 'package:fpdart/fpdart.dart';

import 'account.dart';
import 'account_failure.dart';
import 'i_unit_of_work.dart';

/// Repository contract — lives in the domain package; adapters implement it.
abstract interface class IAccountRepository {
  /// Returns the account with [id]; pass [uow] to read consistently inside a
  /// transaction — most reads won't need it.
  Future<Either<AccountFailure, Account>> get({
    required String id,
    IUnitOfWork? uow,
  });

  /// Creates an account; pass [uow] to join a larger transaction.
  Future<Either<AccountFailure, Account>> create({
    required String id,
    required String holder,
    IUnitOfWork? uow,
  });
}

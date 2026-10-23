import 'package:fpdart/fpdart.dart';

import 'account.dart';
import 'account_failure.dart';
import 'i_account_repository.dart';

/// Fetches one account by its handle.
///
/// A single read steps once, so it takes no unit of work — the seam belongs to
/// the operations that need more than one store interaction to be one step
/// (§5.5).
class GetAccountUseCase {
  final IAccountRepository _repository;

  /// Wraps the [repository] the use case delegates to.
  const GetAccountUseCase(this._repository);

  /// Returns the account with [accountHandle], or [AccountNotFound].
  Future<Either<AccountFailure, Account>> call({
    required String accountHandle,
  }) => _repository.get(accountHandle: accountHandle);
}

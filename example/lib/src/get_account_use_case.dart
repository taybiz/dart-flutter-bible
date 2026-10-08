import 'package:fpdart/fpdart.dart';

import 'account.dart';
import 'account_failure.dart';
import 'i_account_repository.dart';

/// Fetches one account by id.
class GetAccountUseCase {
  final IAccountRepository _repository;

  /// Wraps the [repository] the use case delegates to.
  const GetAccountUseCase(this._repository);

  /// Returns the account with [id], or [AccountNotFound].
  Future<Either<AccountFailure, Account>> call({required String id}) =>
      _repository.get(id: id);
}

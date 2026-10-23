import 'package:fpdart/fpdart.dart';

import 'account.dart';
import 'account_failure.dart';
import 'i_account_repository.dart';

/// In-memory adapter: a legitimate second adapter and the use-case test double.
class InMemoryAccountRepository implements IAccountRepository {
  final Map<String, Account> _accounts = {};

  @override
  Future<Either<AccountFailure, Account>> get({
    required String accountHandle,
  }) async {
    final account = _accounts[accountHandle];
    if (account == null) return Left(AccountNotFound(handle: accountHandle));
    return Right(account);
  }

  @override
  Future<Either<AccountFailure, Account>> create({
    required String accountHandle,
    required String holder,
  }) async {
    if (_accounts.containsKey(accountHandle)) {
      return Left(AccountAlreadyExists(handle: accountHandle));
    }
    final account = Account(handle: accountHandle, holder: holder, balance: 0);
    _accounts[accountHandle] = account;
    return Right(account);
  }
}

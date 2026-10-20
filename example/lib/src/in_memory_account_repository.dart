import 'package:fpdart/fpdart.dart';

import 'account.dart';
import 'account_failure.dart';
import 'i_account_repository.dart';

/// In-memory adapter: a legitimate second adapter and the use-case test double.
class InMemoryAccountRepository implements IAccountRepository {
  final Map<String, Account> _accounts = {};

  @override
  Future<Either<AccountFailure, Account>> get({required String id}) async {
    final account = _accounts[id];
    if (account == null) return Left(AccountNotFound(id: id));
    return Right(account);
  }

  @override
  Future<Either<AccountFailure, Account>> create({
    required String id,
    required String holder,
  }) async {
    if (_accounts.containsKey(id)) {
      return Left(AccountAlreadyExists(id: id));
    }
    final account = Account(id: id, holder: holder, balance: 0);
    _accounts[id] = account;
    return Right(account);
  }
}

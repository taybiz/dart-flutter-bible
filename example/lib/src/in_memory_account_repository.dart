import 'package:fpdart/fpdart.dart';

import 'account.dart';
import 'account_failure.dart';
import 'i_account_repository.dart';
import 'i_unit_of_work.dart';

/// In-memory adapter: a legitimate second adapter and the use-case test double.
class InMemoryAccountRepository implements IAccountRepository {
  final Map<String, Account> _accounts = {};

  @override
  Future<Either<AccountFailure, Account>> get({
    required String id,
    IUnitOfWork? uow,
  }) async {
    // In-memory reads are atomic; uow is accepted for contract uniformity.
    final account = _accounts[id];
    if (account == null) return Left(AccountNotFound(id: id));
    return Right(account);
  }

  @override
  Future<Either<AccountFailure, Account>> create({
    required String id,
    required String holder,
    IUnitOfWork? uow,
  }) async {
    // In-memory ops are atomic; uow is accepted for contract uniformity.
    if (_accounts.containsKey(id)) {
      return Left(AccountAlreadyExists(id: id));
    }
    final account = Account(id: id, holder: holder, balance: 0);
    _accounts[id] = account;
    return Right(account);
  }
}

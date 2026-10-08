import 'package:fpdart/fpdart.dart';

import 'account.dart';
import 'account_failure.dart';
import 'i_account_repository.dart';
import 'i_unit_of_work.dart';

/// Creates an account from discrete business params — never a cargo object.
class CreateAccountUseCase {
  final IAccountRepository _repository;

  /// Wraps the [repository] the use case delegates to.
  const CreateAccountUseCase(this._repository);

  /// Creates the account, or [AccountAlreadyExists]. Pass [uow] to join a
  /// larger transaction when atomicity matters.
  Future<Either<AccountFailure, Account>> call({
    required String id,
    required String holder,
    IUnitOfWork? uow,
  }) => _repository.create(id: id, holder: holder, uow: uow);
}

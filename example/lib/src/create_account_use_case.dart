import 'package:fpdart/fpdart.dart';

import 'account.dart';
import 'account_failure.dart';
import 'i_account_repository.dart';
import 'unit_of_work.dart';

/// Creates an account from discrete business params — never a cargo object.
class CreateAccountUseCase {
  final IAccountRepository _repository;
  final UnitOfWork _unitOfWork;

  /// Wraps the [repository] in the required unit of work — required so no caller
  /// leaves "no transaction" unsaid. A store that cannot roll back is wired with
  /// [noOpUnitOfWork] where this operation is built (§5.5).
  const CreateAccountUseCase(this._repository, {required UnitOfWork unitOfWork})
    : _unitOfWork = unitOfWork;

  /// Creates the account, or [AccountAlreadyExists].
  Future<Either<AccountFailure, Account>> call({
    required String id,
    required String holder,
  }) => _unitOfWork<AccountFailure, Account>(
    body: () => _repository.create(id: id, holder: holder),
  );
}

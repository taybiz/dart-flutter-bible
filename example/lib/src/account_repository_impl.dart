import 'package:fpdart/fpdart.dart';

import 'account.dart';
import 'account_failure.dart';
import 'account_http_adapter.dart';
import 'datasource_failure.dart';
import 'i_account_repository.dart';
import 'i_unit_of_work.dart';

/// Maps low-level datasource failures up into the domain failure layer.
///
/// `DatasourceFailure` must never leak past the repository; this is where the
/// seam between failure hierarchies lives (§4 "Failures are typed values").
AccountFailure mapDatasourceFailure(DatasourceFailure failure) =>
    switch (failure) {
      DatasourceReadFailure(:final reason) => AccountReadFailed(reason: reason),
    };

/// Repository implementation over the HTTP adapter: maps failures upward and
/// never leaks `DatasourceFailure` past the repository boundary.
class AccountRepositoryImpl implements IAccountRepository {
  /// The datasource adapter this repository orchestrates.
  final AccountHttpAdapter adapter;

  /// Creates a repository over [adapter].
  AccountRepositoryImpl({required this.adapter});

  @override
  Future<Either<AccountFailure, Account>> get({
    required String id,
    IUnitOfWork? uow,
  }) => adapter.fetchAccount(id: id).mapLeft(mapDatasourceFailure).run();

  @override
  Future<Either<AccountFailure, Account>> create({
    required String id,
    required String holder,
    IUnitOfWork? uow,
  }) => adapter
      .fetchRawAccount(id: id)
      .map(
        (json) => Account(
          id: json['id']! as String,
          holder: json['holder']! as String,
          balance: 0,
        ),
      )
      .mapLeft(mapDatasourceFailure)
      .run();
}

import 'package:fpdart/fpdart.dart';

import 'account.dart';
import 'datasource_failure.dart';
import 'throwing_http_client.dart';

/// §4 "Composition" made executable: the adapter boundary is a LINE, not a zone.
///
/// The only try/catch-shaped construct in this adapter is [TaskEither.tryCatch]
/// wrapping the third-party call itself — one conversion seam, in the outermost
/// public method, after which failures are values and travel as [Left]. A
/// hand-rolled `try/catch` anywhere in this class would be a violation, and an
/// exception must never cross this class's public API.
class AccountHttpAdapter {
  /// The throwing third-party client this adapter isolates.
  final ThrowingHttpClient client;

  /// Creates an adapter over [client].
  AccountHttpAdapter({required this.client});

  /// Returns the raw account JSON for [id], or [DatasourceReadFailure].
  ///
  /// The instant the client throws, the exception becomes a [Left]; nothing
  /// upstream ever sees `SocketException` (or whatever the SDK threw).
  TaskEither<DatasourceFailure, Map<String, Object?>> fetchRawAccount({
    required String id,
  }) => TaskEither.tryCatch(
    () => client.fetch(token: id),
    (Object error, StackTrace stackTrace) =>
        DatasourceReadFailure(reason: error.toString()),
  );

  /// Returns the parsed [Account] for [id], or the datasource failure.
  ///
  /// Outward of the seam everything is [TaskEither] composition — no `catch`.
  TaskEither<DatasourceFailure, Account> fetchAccount({required String id}) =>
      fetchRawAccount(id: id).map(
        (json) => Account(
          id: json['id']! as String,
          holder: json['holder']! as String,
          balance: 0,
        ),
      );
}

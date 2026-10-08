/// Closed failure hierarchy for the domain layer — exhaustive to switch over.
sealed class AccountFailure {
  /// Base for all domain failures.
  const AccountFailure();
}

/// No account exists for the requested id.
final class AccountNotFound extends AccountFailure {
  /// The missing account id.
  final String id;

  /// Creates a not-found failure for [id].
  const AccountNotFound({required this.id});
}

/// The account already exists; ids must be unique.
final class AccountAlreadyExists extends AccountFailure {
  /// The duplicate account id.
  final String id;

  /// Creates an already-exists failure for [id].
  const AccountAlreadyExists({required this.id});
}

/// The backing store failed while reading; mapped up from `DatasourceFailure`.
final class AccountReadFailed extends AccountFailure {
  /// Human-readable reason, safe to log.
  final String reason;

  /// Creates a read failure with [reason].
  const AccountReadFailed({required this.reason});
}

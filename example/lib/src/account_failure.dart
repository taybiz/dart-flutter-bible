/// Closed failure hierarchy for the domain layer — exhaustive to switch over.
sealed class AccountFailure {
  /// Base for all domain failures.
  const AccountFailure();
}

/// No account exists for the requested handle.
final class AccountNotFound extends AccountFailure {
  /// The missing account handle.
  final String handle;

  /// Creates a not-found failure for [handle].
  const AccountNotFound({required this.handle});
}

/// The account already exists; handles must be unique.
final class AccountAlreadyExists extends AccountFailure {
  /// The duplicate account handle.
  final String handle;

  /// Creates an already-exists failure for [handle].
  const AccountAlreadyExists({required this.handle});
}

/// The backing store failed while reading; mapped up from `DatasourceFailure`.
final class AccountReadFailed extends AccountFailure {
  /// Human-readable reason, safe to log.
  final String reason;

  /// Creates a read failure with [reason].
  const AccountReadFailed({required this.reason});
}

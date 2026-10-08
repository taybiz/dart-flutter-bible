/// Closed failure hierarchy for the datasource layer — exhaustive to switch over.
sealed class DatasourceFailure {
  /// Base for all low-level datasource failures.
  const DatasourceFailure();
}

/// The backing store failed while reading (network, I/O, deserialization, …).
final class DatasourceReadFailure extends DatasourceFailure {
  /// Human-readable reason for logging/diagnostics.
  final String reason;

  /// Creates a read failure with [reason].
  const DatasourceReadFailure({required this.reason});
}

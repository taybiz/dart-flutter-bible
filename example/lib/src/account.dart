import 'package:equatable/equatable.dart';

/// A customer account: the core domain entity.
class Account extends Equatable {
  /// Stable handle: the account's public identifier.
  final String handle;

  /// Display name of the account owner.
  final String holder;

  /// Current balance.
  final double balance;

  /// Creates an account with the given fields.
  const Account({
    required this.handle,
    required this.holder,
    required this.balance,
  });

  /// Returns a copy with [amount] credited; the receiver is never mutated.
  Account deposit({required double amount}) =>
      Account(handle: handle, holder: holder, balance: balance + amount);

  @override
  List<Object?> get props => [handle, holder, balance];
}

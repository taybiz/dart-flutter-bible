import 'package:equatable/equatable.dart';

/// A customer account: the core domain entity.
class Account extends Equatable {
  /// Stable unique identifier.
  final String id;

  /// Display name of the account owner.
  final String holder;

  /// Current balance.
  final double balance;

  /// Creates an account with the given fields.
  const Account({
    required this.id,
    required this.holder,
    required this.balance,
  });

  /// Returns a copy with [amount] credited; the receiver is never mutated.
  Account deposit({required double amount}) =>
      Account(id: id, holder: holder, balance: balance + amount);

  @override
  List<Object?> get props => [id, holder, balance];
}

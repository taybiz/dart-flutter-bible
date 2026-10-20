import 'package:bible_samples/bible_samples.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shouldly/shouldly.dart';
import 'package:test/test.dart';

void main() {
  group('Given a CreateAccountUseCase on an in-memory repository', () {
    final useCase = CreateAccountUseCase(
      InMemoryAccountRepository(),
      unitOfWork: noOpUnitOfWork,
    );

    group('When creating an account with valid business params', () {
      test('Then it returns the created account (Right side)', () async {
        final result = await useCase.call(id: 'acct-1', holder: 'Alice');

        result.isRight().should.be(true);
        result
            .getOrElse((_) => throw StateError('expected Right'))
            .id
            .should
            .be('acct-1');
      });
    });

    group('When creating an account whose id already exists', () {
      test('Then it returns AccountAlreadyExists (Left side)', () async {
        await useCase.call(id: 'acct-1', holder: 'Alice');
        final result = await useCase.call(id: 'acct-1', holder: 'Bob');

        result.isLeft().should.be(true);
        result
            .fold(
              (failure) => failure,
              (_) => throw StateError('expected Left'),
            )
            .should
            .beAssignableTo<AccountAlreadyExists>();
      });
    });
  });

  group('Given a GetAccountUseCase on an empty repository', () {
    final useCase = GetAccountUseCase(InMemoryAccountRepository());

    group('When fetching an unknown id', () {
      test('Then it returns AccountNotFound (Left side)', () async {
        final result = await useCase.call(id: 'missing');

        result.isLeft().should.be(true);
        result
            .fold(
              (failure) => failure,
              (_) => throw StateError('expected Left'),
            )
            .should
            .beAssignableTo<AccountNotFound>();
      });
    });
  });

  group('Given a CreateAccountUseCase whose unit of work is watched', () {
    var entries = 0;
    final useCase = CreateAccountUseCase(
      InMemoryAccountRepository(),
      unitOfWork: <F, T>({required Future<Either<F, T>> Function() body}) {
        entries++;
        return body();
      },
    );

    group('When creating an account', () {
      test('Then the operation enters its unit of work exactly once', () async {
        final result = await useCase.call(id: 'acct-2', holder: 'Carol');

        result.isRight().should.be(true);
        entries.should.be(1);
      });
    });
  });
}

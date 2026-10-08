import 'package:bible_samples/bible_samples.dart';
import 'package:test/test.dart';

/// §4 enforcement test: an adapter converts third-party exceptions at the seam
/// (`TaskEither.tryCatch`), and never lets one cross its public API.
void main() {
  group('Given an adapter over a throwing third-party client', () {
    test(
      'When the client succeeds, Then the account crosses as Right',
      () async {
        final adapter = AccountHttpAdapter(client: ThrowingHttpClient());

        final result = await adapter.fetchAccount(id: 'acct-1').run();

        expect(result.isRight(), isTrue);
        expect(
          result.getOrElse((_) => throw StateError('expected Right')).id,
          'acct-1',
        );
      },
    );

    test('When the third party throws, Then it converts to a Left of '
        'DatasourceFailure, never an exception', () async {
      final client = ThrowingHttpClient()
        ..scripted['acct-1'] = <Exception>[Exception('connection reset')];
      final adapter = AccountHttpAdapter(client: client);

      final result = await adapter.fetchAccount(id: 'acct-1').run();

      // The exception became a VALUE — nothing was thrown.
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<DatasourceReadFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('When the third party throws through the repository, Then the failure '
        'is mapped up to a domain AccountFailure', () async {
      final client = ThrowingHttpClient()
        ..scripted['acct-9'] = <Exception>[Exception('socket closed')];
      final repository = AccountRepositoryImpl(
        adapter: AccountHttpAdapter(client: client),
      );

      final result = await repository.get(id: 'acct-9');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<AccountReadFailed>()),
        (_) => fail('expected Left'),
      );
    });
  });
}

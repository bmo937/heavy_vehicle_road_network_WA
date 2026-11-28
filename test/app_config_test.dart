import 'package:flutter_test/flutter_test.dart';
import 'package:roads_map/utils/app_config.dart';

void main() {
  const google = 'test-google-key';
  const mapTiler = 'test-maptiler-key';

  void expectMissing(Map<String, String> env, String key) {
    expect(
      () => AppConfig.fromEnvironment(env),
      throwsA(isA<ConfigurationException>().having((e) => e.key, 'key', key)),
    );
  }

  group('AppConfig.fromEnvironment', () {
    test('accepts valid keys', () {
      final config =
          AppConfig.fromEnvironment({'gApiKey': google, 'mApiKey': mapTiler});
      expect(config.googleApiKey, google);
      expect(config.mapTilerApiKey, mapTiler);
    });

    test('rejects missing gApiKey', () {
      expectMissing({'mApiKey': mapTiler}, 'gApiKey');
    });

    test('rejects missing mApiKey', () {
      expectMissing({'gApiKey': google}, 'mApiKey');
    });

    test('rejects empty value', () {
      expectMissing({'gApiKey': '', 'mApiKey': mapTiler}, 'gApiKey');
    });

    test('rejects whitespace-only value', () {
      expectMissing({'gApiKey': google, 'mApiKey': '   \t'}, 'mApiKey');
    });

    test('error message does not contain secret values', () {
      try {
        AppConfig.fromEnvironment({'gApiKey': google, 'mApiKey': ' '});
        fail('expected exception');
      } on ConfigurationException catch (e) {
        expect(e.toString(), isNot(contains(google)));
        expect(e.toString(), contains('mApiKey'));
      }
    });
  });
}

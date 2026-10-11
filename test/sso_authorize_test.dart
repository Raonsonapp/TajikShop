import 'package:flutter_test/flutter_test.dart';
import 'package:tajikshop/core/services/sso_authorize.dart';

void main() {
  group('SsoAuthorizeRequest.tryParse', () {
    test('accepts tajikshop://sso/authorize?app=raonson&state=…', () {
      final r = SsoAuthorizeRequest.tryParseString(
          'tajikshop://sso/authorize?app=raonson&state=Abc123_-xyz.~9');
      expect(r, isNotNull);
      expect(r!.app, 'raonson');
      expect(r.state, 'Abc123_-xyz.~9');
    });

    test('state is optional', () {
      final r = SsoAuthorizeRequest.tryParseString(
          'tajikshop://sso/authorize?app=raonson');
      expect(r, const SsoAuthorizeRequest(app: 'raonson'));
    });

    test('normalises app case/whitespace and trailing slash', () {
      final r = SsoAuthorizeRequest.tryParseString(
          'TAJIKSHOP://SSO/authorize/?app=%20Raonson%20&state=12345678');
      expect(r?.app, 'raonson');
      expect(r?.state, '12345678');
    });

    test('rejects other schemes, hosts and paths', () {
      for (final raw in [
        'raonson://sso/authorize?app=raonson&state=12345678',
        'https://sso/authorize?app=raonson',
        'tajikshop://evil/authorize?app=raonson',
        'tajikshop://sso/authorise?app=raonson',
        'tajikshop://sso?code=abcdefghijklmnopqrstu', // коди handoff, на authorize
        'tajikshop://sso/authorize/extra?app=raonson',
      ]) {
        expect(SsoAuthorizeRequest.tryParseString(raw), isNull, reason: raw);
      }
    });

    test('rejects missing / malformed / self app', () {
      for (final raw in [
        'tajikshop://sso/authorize',
        'tajikshop://sso/authorize?app=',
        'tajikshop://sso/authorize?app=r',
        'tajikshop://sso/authorize?app=rao%20nson',
        'tajikshop://sso/authorize?app=raonson.evil',
        'tajikshop://sso/authorize?app=tajikshop',
      ]) {
        expect(SsoAuthorizeRequest.tryParseString(raw), isNull, reason: raw);
      }
    });

    test('rejects suspicious state instead of forwarding it', () {
      for (final raw in [
        'tajikshop://sso/authorize?app=raonson&state=short',
        'tajikshop://sso/authorize?app=raonson&state=has%20space1',
        'tajikshop://sso/authorize?app=raonson&state=a%26code%3Dxyz123',
        'tajikshop://sso/authorize?app=raonson&state=${'a' * 300}',
      ]) {
        expect(SsoAuthorizeRequest.tryParseString(raw), isNull, reason: raw);
      }
    });

    test('null/empty input', () {
      expect(SsoAuthorizeRequest.tryParseString(null), isNull);
      expect(SsoAuthorizeRequest.tryParseString('  '), isNull);
    });
  });

  group('SsoAuthorizeRequest.buildReturnLink', () {
    test('appends state to the server deep link', () {
      final u = SsoAuthorizeRequest.buildReturnLink(
          deepLink: 'raonson://sso?code=dX7abc_-Q', expectedScheme: 'raonson',
          state: 'st4te-123');
      expect(u.toString(), 'raonson://sso?code=dX7abc_-Q&state=st4te-123');
      expect(u!.queryParameters['code'], 'dX7abc_-Q');
    });

    test('without state returns the link unchanged', () {
      final u = SsoAuthorizeRequest.buildReturnLink(
          deepLink: 'raonson://sso?code=abc', expectedScheme: 'raonson');
      expect(u.toString(), 'raonson://sso?code=abc');
    });

    test('a state already in the link is replaced, not duplicated', () {
      final u = SsoAuthorizeRequest.buildReturnLink(
          deepLink: 'raonson://sso?code=abc&state=old',
          expectedScheme: 'raonson',
          state: 'new-state-1');
      expect(u!.queryParametersAll['state'], ['new-state-1']);
    });

    test('refuses a link to a different app', () {
      expect(
          SsoAuthorizeRequest.buildReturnLink(
              deepLink: 'evil://sso?code=abc', expectedScheme: 'raonson',
              state: 'st4te-123'),
          isNull);
      expect(
          SsoAuthorizeRequest.buildReturnLink(
              deepLink: 'raonson://sso?code=abc', expectedScheme: ''),
          isNull);
    });
  });

  group('SsoPartnerApp', () {
    final env = {
      'success': true,
      'data': [
        {'id': 'raonson', 'name': 'Raonson', 'scheme': 'raonson',
         'fallback': 'https://play.google.com/store/apps/details?id=com.raonson.app'},
        {'id': 'tajikshop', 'name': 'TajikShop', 'scheme': 'tajikshop'},
        {'id': 'noscheme', 'name': 'X'},
      ],
    };

    test('parses /sso/apps and finds the requested app', () {
      final apps = SsoPartnerApp.listFrom(env);
      expect(apps, hasLength(3));
      final a = SsoPartnerApp.find(apps, 'Raonson');
      expect(a?.scheme, 'raonson');
      expect(a?.name, 'Raonson');
    });

    test('unknown or scheme-less app is not valid', () {
      final apps = SsoPartnerApp.listFrom(env);
      expect(SsoPartnerApp.find(apps, 'other'), isNull);
      expect(SsoPartnerApp.find(apps, 'noscheme'), isNull);
      expect(SsoPartnerApp.listFrom('garbage'), isEmpty);
    });
  });
}

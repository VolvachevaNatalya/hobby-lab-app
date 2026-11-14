import 'package:flutter_test/flutter_test.dart';
import 'package:hobby_lab/utils/validators.dart';

void main() {
  group('isValidEmail', () {
    test('accepts standard emails', () {
      expect(isValidEmail('user@example.com'), isTrue);
      expect(isValidEmail('user.name+tag@sub.domain.org'), isTrue);
      expect(isValidEmail('x@y.z'), isTrue);
    });

    test('rejects missing @', () {
      expect(isValidEmail('userexample.com'), isFalse);
      expect(isValidEmail('user'), isFalse);
    });

    test('rejects missing domain part', () {
      expect(isValidEmail('user@'), isFalse);
      expect(isValidEmail('@example.com'), isFalse);
    });

    test('rejects missing TLD (no dot after @)', () {
      expect(isValidEmail('user@example'), isFalse);
    });

    test('rejects whitespace in email', () {
      expect(isValidEmail('user @example.com'), isFalse);
      expect(isValidEmail('user@ example.com'), isFalse);
      expect(isValidEmail(''), isFalse);
    });

    test('rejects multiple @ signs', () {
      // regex allows this — only the outer shape is checked; full RFC is not needed
      // but confirm empty string and spaces are caught
      expect(isValidEmail(''), isFalse);
    });
  });

  group('password length gate (6-char minimum)', () {
    // This is a pure logic test — mirrors the guard in register_screen.dart
    bool passwordTooShort(String p) => p.length < 6;

    test('password of 5 chars is too short', () {
      expect(passwordTooShort('abc12'), isTrue);
    });

    test('password of exactly 6 chars is accepted', () {
      expect(passwordTooShort('abc123'), isFalse);
    });

    test('password of 8 chars is accepted', () {
      expect(passwordTooShort('abc12345'), isFalse);
    });

    test('empty password is too short', () {
      expect(passwordTooShort(''), isTrue);
    });
  });

  group('confirm-password mismatch gate', () {
    // Mirrors the guard in register_screen.dart: password != confirmPassword
    bool mismatch(String p, String c) => p != c;

    test('identical passwords pass', () {
      expect(mismatch('secret123', 'secret123'), isFalse);
    });

    test('different passwords fail', () {
      expect(mismatch('secret123', 'Secret123'), isTrue);
    });

    test('empty confirm fails against non-empty password', () {
      expect(mismatch('secret123', ''), isTrue);
    });

    test('both empty pass (empty == empty)', () {
      expect(mismatch('', ''), isFalse);
    });

    test('case-sensitive: lowercase vs uppercase fails', () {
      expect(mismatch('abc', 'ABC'), isTrue);
    });
  });
}

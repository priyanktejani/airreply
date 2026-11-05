import 'dart:typed_data';

import 'package:air_reply/core/crypto/crypto_service.dart';
import 'package:air_reply/features/mirror/domain/entities/notification_content.dart';
import 'package:air_reply/features/sender/domain/usecases/relay_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

/// firestore.rules refuses a payload of this many characters or more.
const _serverLimit = 16384;

NotificationContent _content({String title = 'Asha', required String text, Uint8List? icon}) => NotificationContent(
  key: 'k',
  packageName: 'com.whatsapp',
  appName: 'WhatsApp',
  title: title,
  text: text,
  postedAt: DateTime(2026, 11, 5),
  iconPng: icon,
);

Future<int> _sealedLength(NotificationContent c) async =>
    (await CryptoService().seal(c.toJson(), key: Uint8List(32), context: 'p|notification')).length;

void main() {
  final icon = Uint8List(PublishCapturedNotification.maxIconBytes);
  // as long as the phone lets through: 4,000 characters, in scripts that take three or four bytes each
  final hindi = 'नमस्ते ' * 571;
  final emoji = '🎉' * 4000;

  test('the longest messages in any script, with an icon, still fit the server once sealed', () async {
    for (final text in [hindi, emoji, 'a' * 4000]) {
      final fitted = PublishCapturedNotification.fit(_content(text: text, icon: icon));
      expect(await _sealedLength(fitted), lessThan(_serverLimit));
    }
  });

  test('before this, such a message was refused by the server (so it never arrived)', () async {
    expect(await _sealedLength(_content(text: hindi, icon: icon)), greaterThanOrEqualTo(_serverLimit));
  });

  test('what fits is left alone; the icon goes before any text; cut text ends with an ellipsis, whole characters', () {
    final small = _content(text: 'Dinner at 8?', icon: Uint8List(100));
    expect(identical(PublishCapturedNotification.fit(small), small), isTrue);

    final ascii = PublishCapturedNotification.fit(_content(text: 'a' * 4000, icon: icon));
    expect(ascii.iconPng, isNull);
    expect(ascii.text, 'a' * 4000, reason: 'dropping the icon was enough');

    final cut = PublishCapturedNotification.fit(_content(text: emoji, icon: icon));
    expect(cut.text.endsWith('…'), isTrue);
    expect(cut.text.runes.where((r) => r != 0x2026).every((r) => r == 0x1F389), isTrue, reason: 'no broken emoji');
  });

  test('a huge title is shortened too', () async {
    final fitted = PublishCapturedNotification.fit(_content(title: '名' * 6000, text: '名' * 4000));
    expect(await _sealedLength(fitted), lessThan(_serverLimit));
    expect(fitted.title.endsWith('…'), isTrue);
  });
}

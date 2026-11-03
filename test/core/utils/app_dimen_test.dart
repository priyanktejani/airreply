import 'package:air_reply/core/utils/app_dimen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('window widths map to Material window classes', () {
    expect(ScreenType.fromWidth(320), ScreenType.mobile);
    expect(ScreenType.fromWidth(599), ScreenType.mobile);
    expect(ScreenType.fromWidth(600), ScreenType.tablet);
    expect(ScreenType.fromWidth(839), ScreenType.tablet);
    expect(ScreenType.fromWidth(840), ScreenType.desktop);
    expect(ScreenType.fromWidth(1440), ScreenType.desktop);
  });
}

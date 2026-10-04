import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/consts.dart';

void main() {
  test('peer sidebar options default to hidden and round-trip saved choices',
      () {
    for (final key in [kOptionHideAbTagsPanel, kOptionHideMyGroupUsersPanel]) {
      expect(option2bool(key, ''), isTrue);
      expect(option2bool(key, 'Y'), isTrue);
      expect(option2bool(key, 'N'), isFalse);
      for (final hidden in [false, true]) {
        final saved = bool2option(key, hidden);
        expect(saved, hidden ? 'Y' : 'N');
        expect(option2bool(key, saved), hidden);
      }
    }
  });
}
